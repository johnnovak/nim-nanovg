gcc -c src\deps\glad.c -o lib\glad.o
gcc -c src\nanovg\nanovg.c -o lib\nanovg.o
rem gcc -DNANOVG_GL2_IMPLEMENTATION -c src\nanovg_gl_stub.c -o lib\nanovg_gl2_stub.o
rem gcc -DNANOVG_GL3_IMPLEMENTATION -c src\nanovg_gl_stub.c -o lib\nanovg_gl3_stub.o
rem gcc -DNANOVG_GLES2_IMPLEMENTATION -c src\nanovg_gl_stub.c -o lib\nanovg_gles2_stub.o
rem gcc -DNANOVG_GLES3_IMPLEMENTATION -c src\nanovg_gl_stub.c -o lib\nanovg_gles3_stub.o
