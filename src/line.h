#ifndef LINE_H
#define LINE_H

#include <godot_cpp/classes/node3d.hpp>

namespace godot {

    class line : public Node3D {
        GDCLASS(line, Node3D)

    private:
        double myvariable;

    protected:
        static void _bind_methods();

    public:
        line();
        ~line();

        void computeLine(Vector3 a, Vector3 b, Color color, float thickness, Node3D *l);
    };

}

#endif