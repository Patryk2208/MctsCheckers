//
// Created by patryk on 1/21/26.
//
#include <tocpuwb/serialization.hpp>

MctsStorage::MctsStorage(const std::string& db_path) {
    sqlite3_open(db_path.c_str(), &db_);
    CreateTables();
}

MctsStorage::~MctsStorage() {
    if (!db_) return;
    sqlite3_close(db_);
}

void MctsStorage::CreateTables() const {
    const char* sql = R"(
        CREATE TABLE IF NOT EXISTS mcts_nodes (
            node_id INTEGER PRIMARY KEY,
            parent_id INTEGER,
            children_count INTEGER,
            state_white_pawns INTEGER,
            state_black_pawns INTEGER,
            state_white_queens INTEGER,
            state_black_queens INTEGER,
            state_metadata INTEGER,
            visitCount INTEGER DEFAULT 0,
            reward REAL DEFAULT 0.0,
            FOREIGN KEY (parent_id) REFERENCES mcts_nodes(node_id)
        );
        CREATE INDEX IF NOT EXISTS idx_parent ON mcts_nodes(parent_id);
    )";
    sqlite3_exec(db_, sql, nullptr, nullptr, nullptr);
}

void MctsStorage::SaveTree(MctsTocpuwbNode* root) {
    if (!root) return;

    // Prepare batch insert statement
    const auto insert_sql = R"(
        INSERT OR REPLACE INTO mcts_nodes
        (node_id, parent_id, children_count, state_white_pawns, state_black_pawns,
        state_white_queens, state_black_queens, state_metadata, visitCount, reward)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    )";

    sqlite3_stmt* stmt;
    if (sqlite3_prepare_v2(db_, insert_sql, -1, &stmt, nullptr) != SQLITE_OK) {
        throw std::runtime_error("Failed to prepare statement");
    }

    // Traverse tree and save all nodes in batches
    std::vector<MctsTocpuwbNode*> nodes_to_process = {root};
    std::vector<MctsTocpuwbNode*> all_nodes;

    // Collect all nodes using BFS
    while (!nodes_to_process.empty()) {
        MctsTocpuwbNode* node = nodes_to_process.back();
        nodes_to_process.pop_back();
        all_nodes.push_back(node);

        for (auto i = 0; i < node->childrenCount_; i++) {
            nodes_to_process.push_back(&node->children_[i]);
        }
    }

    // Assign IDs to all nodes
    for (MctsTocpuwbNode* node : all_nodes) {
        if (!node_to_id_.contains(node)) {
            node_to_id_[node] = next_id_++;
            id_to_node_[node_to_id_[node]] = node;
        }
    }

    // Save all nodes in a transaction
    sqlite3_exec(db_, "BEGIN TRANSACTION", nullptr, nullptr, nullptr);

    try {
        for (MctsTocpuwbNode* node : all_nodes) {
            int64_t node_id = node_to_id_[node];
            int64_t parent_id = (node->parent_ && node_to_id_.contains(node->parent_)) ? node_to_id_[node->parent_] : 0;

            sqlite3_bind_int64(stmt, 1, node_id);
            sqlite3_bind_int64(stmt, 2, parent_id);
            sqlite3_bind_int64(stmt, 3, node->childrenCount_);
            sqlite3_bind_int64(stmt, 4, node->state_.whitePawns_);
            sqlite3_bind_int64(stmt, 5, node->state_.blackPawns_);
            sqlite3_bind_int64(stmt, 6, node->state_.whiteQueens_);
            sqlite3_bind_int64(stmt, 7, node->state_.blackQueens_);
            sqlite3_bind_int64(stmt, 8, node->state_.metadata_);
            sqlite3_bind_int64(stmt, 9, node->visitCount_);
            sqlite3_bind_double(stmt, 10, node->reward_);

            if (sqlite3_step(stmt) != SQLITE_DONE) {
                throw std::runtime_error("Failed to insert node");
            }

            sqlite3_reset(stmt);
        }

        sqlite3_finalize(stmt);
        sqlite3_exec(db_, "COMMIT", nullptr, nullptr, nullptr);

    } catch (...) {
        sqlite3_finalize(stmt);
        sqlite3_exec(db_, "ROLLBACK", nullptr, nullptr, nullptr);
        throw;
    }
}

MctsTocpuwbNode* MctsStorage::LoadTree() {
     // Clear previous mappings
    id_to_node_.clear();
    node_to_id_.clear();
    id_to_children_already_loaded.clear();
    next_id_ = 1;
    
    // Query to load tree structure using recursive CTE
    // We'll load nodes breadth-first from the specified root
    const auto query_sql = R"(
        WITH RECURSIVE mcts_tree AS (
            -- Anchor: start from the root
            SELECT node_id, parent_id, children_count, state_white_pawns, state_black_pawns,
                   state_white_queens, state_black_queens,
                   state_metadata, visitCount, reward,
                   0 as depth
            FROM mcts_nodes
            WHERE node_id = ?
            
            UNION ALL
            
            -- Recursive: get all children
            SELECT n.node_id, n.parent_id, n.children_count, n.state_white_pawns, n.state_black_pawns,
                   n.state_white_queens, n.state_black_queens,
                   n.state_metadata, n.visitCount, n.reward,
                   t.depth + 1 as depth
            FROM mcts_nodes n
            INNER JOIN mcts_tree t ON n.parent_id = t.node_id
        )
        SELECT node_id, parent_id, children_count, state_white_pawns, state_black_pawns,
               state_white_queens, state_black_queens,
               state_metadata, visitCount, reward, depth
        FROM mcts_tree
        ORDER BY depth, node_id
    )";
    
    sqlite3_stmt* stmt;
    if (sqlite3_prepare_v2(db_, query_sql, -1, &stmt, nullptr) != SQLITE_OK) {
        throw std::runtime_error("Failed to prepare query statement: " + 
                                 std::string(sqlite3_errmsg(db_)));
    }
     constexpr auto root_id = 1;
    sqlite3_bind_int64(stmt, 1, root_id);

    MctsTocpuwbNode* root = nullptr;
    
    try {
        // Single pass: create nodes and build parent-child relationships
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            int64_t node_id = sqlite3_column_int64(stmt, 0);
            int64_t parent_id = sqlite3_column_int64(stmt, 1);
            int children_count = sqlite3_column_int(stmt, 2);
            if (parent_id == 0) {
                //root
                root = new MctsTocpuwbNode();
                node_to_id_[root] = node_id;
                id_to_node_[node_id] = root;
                id_to_children_already_loaded[node_id] = 0;

                root->parent_ = nullptr;
                root->childrenCount_ = children_count;
                root->children_ = new MctsTocpuwbNode[children_count];
                root->state_ = CheckersState{
                    static_cast<BoardMap>(sqlite3_column_int64(stmt, 3)),
                    static_cast<BoardMap>(sqlite3_column_int64(stmt, 4)),
                    static_cast<BoardMap>(sqlite3_column_int64(stmt, 5)),
                    static_cast<BoardMap>(sqlite3_column_int64(stmt, 6)),
                    static_cast<BoardMapMetadata>(sqlite3_column_int64(stmt, 7))
                };
                root->visitCount_ = static_cast<int>(sqlite3_column_int64(stmt, 8));
                root->reward_ = static_cast<float>(sqlite3_column_double(stmt, 9));
            }
            else {
                const auto p = id_to_node_[parent_id];
                const auto pcc = id_to_children_already_loaded[parent_id]++;
                auto node = &p->children_[pcc];
                node_to_id_[node] = node_id;
                id_to_node_[node_id] = node;
                id_to_children_already_loaded[node_id] = 0;

                node->parent_ = p;
                node->childrenCount_ = children_count;
                node->children_ = new MctsTocpuwbNode[children_count];
                node->state_ = CheckersState{
                    static_cast<BoardMap>(sqlite3_column_int64(stmt, 3)),
                    static_cast<BoardMap>(sqlite3_column_int64(stmt, 4)),
                    static_cast<BoardMap>(sqlite3_column_int64(stmt, 5)),
                    static_cast<BoardMap>(sqlite3_column_int64(stmt, 6)),
                    static_cast<BoardMapMetadata>(sqlite3_column_int64(stmt, 7))
                };
                node->visitCount_ = static_cast<int>(sqlite3_column_int64(stmt, 8));
                node->reward_ = static_cast<float>(sqlite3_column_double(stmt, 9));
            }
            
            // Update next_id_
            if (node_id >= next_id_) {
                next_id_ = node_id + 1;
            }
        }
        if (root == nullptr) throw std::runtime_error("root was not allocated");
        
    } catch (...) {
        sqlite3_finalize(stmt);
        throw;
    }
    
    sqlite3_finalize(stmt);
    
    return root;
}
