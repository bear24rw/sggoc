#define IMGUI_DEFINE_MATH_OPERATORS 1

#include "v_sggoc.h"
#include "v_sggoc___024root.h"
#include "v_sggoc_sggoc.h"
#include "v_sggoc_vdp.h"
#include "v_sggoc_vram.h"
#include "verilated.h"
#include <GLFW/glfw3.h>
#include <cassert>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <imgui.h>
#include <imgui_impl_glfw.h>
#include <imgui_impl_opengl3.h>
#include <imgui_internal.h>
#include <thread>
#include <vector>

bool paused = false;

v_sggoc* tb;
v_sggoc___024root* root;

std::vector<uint8_t> g_rom;
std::vector<uint8_t> g_ram;

static uint8_t pixels[512][512][3];

uint64_t ticks = 0;
uint16_t ticks_delay_us = 0;
double clock_mhz = 50.0;

inline double ticks_to_ms(uint64_t _ticks)
{
    return (1.0 / (clock_mhz * 1e3)) * _ticks;
}

double timestamp = 0;
double sc_time_stamp() { return timestamp; }

void tick(uint64_t amount = 1)
{
    // stimulous might have changed since last tick
    tb->eval();

    for (uint64_t i = 0; i < amount; i++) {
        for (uint8_t clk = 0; clk < 2; clk++) {
            tb->clk = ~tb->clk;
            tb->eval();
            timestamp += (1.0 / clock_mhz) / 2.0 / 1e6;
        }
        ticks++;
    }
    // if (ticks > 100) exit(1);

    if (ticks_delay_us)
        std::this_thread::sleep_for(std::chrono::microseconds(ticks_delay_us));
}

void reset()
{
    tb->clk = 0;
    tb->rst = 0;
    tick(1);
    tb->rst = 1;
    tick(1);
    tb->rst = 0;
    tick(1);
}

void sim_loop()
{
    reset();

    while (true) {
        if (paused) continue;
        tick();
        // printf("RAM: %x ROM: %x\n", tb->ram_addr, tb->rom_addr);
        // if (tb->sggoc__DOT__mmu__DOT____Vtogcov__cart_en)
        // assert(tb->rom_addr < g_rom.size());
        // if (root->sggoc__DOT__mmu__DOT____Vtogcov__ram_en)
        //    assert(root->ram_addr < g_ram.size());
        if (root->ram_we)
            g_ram[root->ram_addr] = root->ram_di;
        // if (root->sggoc__DOT__z80_mem_rd)
        //     printf("mem_rd %x = %x\n", root->rom_addr, g_rom[root->rom_addr]);
        root->ram_do = g_ram[root->ram_addr];
        root->rom_do = g_rom[root->rom_addr];
        int x = root->sggoc->vdp->pixel_x;
        int y = root->sggoc->vdp->pixel_y;
        if (x < 512 && y < 512) {
            pixels[y][x][0] = root->VGA_R;
            pixels[y][x][1] = root->VGA_G;
            pixels[y][x][2] = root->VGA_B;
        }
    }
}

void draw_vga()
{
    ImGui::Begin("vga");
    ImVec2 cursor_pos = ImGui::GetCursorScreenPos();
    for (int x = 0; x < 512; x++) {
        for (int y = 0; y < 512; y++) {
            ImVec2 a { cursor_pos.x + x, cursor_pos.y + y };
            ImVec2 b { cursor_pos.x + x + 1, cursor_pos.y + y + 1 };
            auto color = ImColor(
                pixels[y][x][0] * 15,
                pixels[y][x][1] * 15,
                pixels[y][x][2] * 15);
            ImGui::GetWindowDrawList()->AddRectFilled(a, b, color);
        }
    }
    ImGui::End();
}

void draw_ram()
{
    ImGui::Begin("ram");
    ImGui::LabelText("RAM Addr", "0x%X", root->ram_addr);
    ImGui::LabelText("RAM Do", "0x%X", g_ram[root->ram_addr]);
    ImGui::LabelText("RAM Di", "0x%X", root->ram_di);
    ImGui::LabelText("RAM We", "0x%X", root->ram_we);
    ImVec2 cursor_pos = ImGui::GetCursorScreenPos();
    for (int x = 0; x < 64; x++) {
        for (int y = 0; y < 128; y++) {
            ImVec2 a { cursor_pos.x + x, cursor_pos.y + y };
            ImVec2 b { cursor_pos.x + x + 1, cursor_pos.y + y + 1 };
            auto color = ImColor(
                g_ram[y * 64 + x],
                g_ram[y * 64 + x],
                g_ram[y * 64 + x]);
            ImGui::GetWindowDrawList()->AddRectFilled(a, b, color);
        }
    }
    ImGui::End();
}

void draw_vram()
{
    ImGui::Begin("vram");
    float size = 4.0;
    ImVec2 cursor_pos = ImGui::GetCursorScreenPos();
    for (int x = 0; x < 128; x++) {
        for (int y = 0; y < 128; y++) {
            ImVec2 a { cursor_pos.x + x * size, cursor_pos.y + y * size };
            ImVec2 b { cursor_pos.x + x * size + size, cursor_pos.y + y * size + size };
            auto color = ImColor(
                root->sggoc->vdp->vram->ram[y * 128 + x],
                root->sggoc->vdp->vram->ram[y * 128 + x],
                root->sggoc->vdp->vram->ram[y * 128 + x]);
            ImGui::GetWindowDrawList()->AddRectFilled(a, b, color);
        }
    }
    ImGui::End();
}

void draw_rom()
{
    ImGui::Begin("ROM");
    ImGui::LabelText("ROM Addr", "0x%X", root->rom_addr);
    ImGui::LabelText("ROM Do", "0x%X", g_rom[root->rom_addr]);
    /*
    ImVec2 cursor_pos = ImGui::GetCursorScreenPos();
    for (size_t i = 0; i < g_rom.size(); i++) {
        int x = i % 128;
        int y = i / 128;
            ImVec2 a { cursor_pos.x + x, cursor_pos.y + y};
            ImVec2 b { cursor_pos.x + x + 1, cursor_pos.y + y + 1};
            auto color = ImColor(
                    g_rom[i],
                    g_rom[i],
                    g_rom[i]
                    );
            ImGui::GetWindowDrawList()->AddRectFilled(a, b, color);
    }
    */
    ImGui::End();
}

void draw_time()
{
    ImGui::Begin("Time");
    if (ImGui::Button(paused ? "Continue" : "Pause")) {
        paused = !paused;
    }
    ImGui::Text("Ticks: %llu (%fms)", ticks, ticks_to_ms(ticks));
    int delay = ticks_delay_us;
    ImGui::SliderInt("Tick delay (us)", &delay, 0, 10000);
    ticks_delay_us = delay;
    ImGui::End();
}

int main(int argc, char** argv)
{
    assert(argc == 2);
    std::ifstream instream(argv[1], std::ios::in | std::ios::binary);
    g_rom = std::vector<uint8_t>((std::istreambuf_iterator<char>(instream)), std::istreambuf_iterator<char>());
    g_ram.resize(1 << 13);
    printf("RAM Size: %zu\n", g_ram.size());
    printf("ROM Size: %zu\n", g_rom.size());
    assert(g_rom.size() % 1024 != 512); // padded rom

    if (!glfwInit())
        return 1;

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE); // 3.2+ only
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);           // Required on Mac

    GLFWwindow* window = glfwCreateWindow(1280, 720, "Dear ImGui GLFW+OpenGL3 example", NULL, NULL);
    assert(window);
    glfwMakeContextCurrent(window);
    glfwSwapInterval(1); // Enable vsync

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 150");

    tb = new v_sggoc;
    root = tb->rootp;

    std::thread sim_thread = std::thread(sim_loop);

    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();

        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplGlfw_NewFrame();
        ImGui::NewFrame();

        draw_time();
        draw_rom();
        draw_vram();
        draw_vga();
        draw_ram();

        ImGui::Render();
        int display_w, display_h;
        glfwMakeContextCurrent(window);
        glfwGetFramebufferSize(window, &display_w, &display_h);
        glViewport(0, 0, display_w, display_h);
        glClearColor(0.2f, 0.2f, 0.2f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());

        glfwMakeContextCurrent(window);
        glfwSwapBuffers(window);
    }

    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();

    glfwDestroyWindow(window);
    glfwTerminate();

    return 0;
}
