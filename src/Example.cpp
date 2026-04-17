#include "Example.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/classes/engine.hpp>

using namespace godot;

void Example::_bind_methods() {

}

Example::Example() {
    if (Engine::get_singleton()->is_editor_hint()) {
        set_process_mode(Node::ProcessMode::PROCESS_MODE_DISABLED);
    }
    UtilityFunctions::print("testing");
}

Example::~Example() {
	// Add your cleanup here.
}

void Example::speak_lol(String words) {

}

void Example::_process(double delta) {
    UtilityFunctions::print("hi guyz");
}
