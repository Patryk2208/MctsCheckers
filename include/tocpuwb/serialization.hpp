//
// Created by patryk on 1/21/26.
//

#ifndef MCTS_CHECKERS_SERIALIZATION_HPP
#define MCTS_CHECKERS_SERIALIZATION_HPP

#include "sqlite3.h"
#include <string>
#include <memory>
#include <unordered_map>

#include "tree.hpp"


class MctsStorage {
public:
    MctsStorage(const std::string& db_path);
    ~MctsStorage();

    void SaveTree(MctsTocpuwbNode *root);
    MctsTocpuwbNode* LoadTree();

private:
    sqlite3* db_;
    std::unordered_map<int64_t, MctsTocpuwbNode*> id_to_node_;
    std::unordered_map<MctsTocpuwbNode*, int64_t> node_to_id_;
    std::unordered_map<int64_t, int> id_to_children_already_loaded;
    int64_t next_id_ = 1;

    void CreateTables() const;
};

#endif //MCTS_CHECKERS_SERIALIZATION_HPP