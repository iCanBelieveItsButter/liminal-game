#ifndef EXAMPLE_H
#define EXAMPLE_H

#include <godot_cpp/classes/node2d.hpp>

namespace godot {

    class Example : public Node2D {
        GDCLASS(Example, Node2D)

    private:
        double myvariable;

    protected:
        static void _bind_methods();

    public:
        Example();
        ~Example();

        void speak_lol(String words);
        void _process(double delta) override;
    };

}

#endif