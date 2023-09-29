#include <memory>
#include <iostream>

// Define a comparison function for nodes in the priority queue
// struct CompareNodes {
//     bool operator()(const std::shared_ptr<Node3D>& a, const std::shared_ptr<Node3D>& b) const {
//         return a->f_cost > b->f_cost;
//     }
// };

// Define the Node3D struct
struct Node3D {
    int x, y, z;        // 3D coordinates
    double g_cost;      // cost from the start node
    double h_cost;      // heuristic cost to the goal
    double f_cost;      // f_cost = g_cost + h_cost
    std::shared_ptr<Node3D> parent; // shared_ptr to the parent node

    // Constructor
    Node3D(int x, int y, int z)
        : x(x), y(y), z(z), g_cost(0), h_cost(0), f_cost(0), parent(nullptr) {}
public:
    void print() {
        std::cout << "Node3D: x: " << x << ", y: " << y << ", z: " << z << std::endl;
    }
};