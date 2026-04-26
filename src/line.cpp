#include "line.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/variant/transform3d.hpp>

using namespace godot;

void line::_bind_methods () {
    ClassDB::bind_method(D_METHOD("computeLine", "a", "b", "color", "thickness", "l"), &line::computeLine);
}

line::line() {
}

line::~line() {
    //cleanup
}

void line::computeLine(Vector3 a, Vector3 b, Color color, float thickness, Node3D *l) {
    Vector3 dir = (b - a).normalized();
    Vector3 right = dir.cross( Vector3(0, 1, 0) );

    if (right.length() < 0.001) {
        right = dir.cross( Vector3(1, 0, 0) );
    }

    right = right.normalized();
    Vector3 up = right.cross(dir);

    float c = 0.003;

    l->set_basis( Basis(right, up, dir) );
    l->set_position( (a + b) / 2);
    l->set_scale( Vector3(thickness, thickness, a.distance_to(b) + c) );
}