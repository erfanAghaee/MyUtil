#include <iostream>
#include <boost/algorithm/string.hpp>
#include "src/Node3D.h"

// Hey I am changing main.cpp

int main() {

    std::shared_ptr<Node3D> start = std::make_shared<Node3D>(1,1,1);
    std::shared_ptr<Node3D> goal = std::make_shared<Node3D>(2,2,2);


    start->print();
    goal->print();

    // std::string str = "Boost is awesome!";
    // boost::to_upper(str);
    // std::cout << str << std::endl;
    return 0;
}