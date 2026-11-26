#include "ak/core.hpp"
#include <cstdio>
#include <cmath>
static int fails = 0;
#define CHECK(c) do { if (!(c)) { std::printf("FAIL line %d: %s\n", __LINE__, #c); ++fails; } } while (0)
int main() {
    static_assert(ak::asset_id("a") != ak::asset_id("b"));
    CHECK(ak::asset_id("textures/rock.png") == ak::asset_id("textures/rock.png"));
    CHECK(ak::asset_id("") == 1469598103934665603ull);
    // precision far from origin: 1e7 m away, 0.25 m offset must survive
    ak::WorldPos o{1e7, 0, 1e7}, p{1e7 + 0.25, 0, 1e7};
    CHECK(std::fabs(ak::local_offset(p, o).x - 0.25f) < 1e-6f);
    CHECK(ak::needs_rebase({5000, 0, 0}, {0, 0, 0}, 4096));
    CHECK(!ak::needs_rebase({100, 0, 0}, {0, 0, 0}, 4096));
    ak::FrameStats s;
    for (int i = 0; i < 99; ++i) s.add(0.01);
    s.add(0.05);
    CHECK(s.count() == 100);
    CHECK(std::fabs(s.avg_fps() - 100.0 / 1.04) < 1e-6);
    CHECK(std::fabs(s.low1_fps() - 20.0) < 1e-9);
    // renderer switch: 2D -> Godot, 3D -> O3DE when available, else Godot with fallback flag
    CHECK(ak::classify_game(0, 0) == ak::GameKind::Unknown);
    CHECK(ak::classify_game(40, 3) == ak::GameKind::Game2D);
    CHECK(ak::classify_game(2, 30) == ak::GameKind::Game3D);
    CHECK(ak::select_renderer(ak::GameKind::Game2D, true).kind == ak::RendererKind::Godot);
    CHECK(ak::select_renderer(ak::GameKind::Game3D, true).kind == ak::RendererKind::O3DE);
    CHECK(ak::select_renderer(ak::GameKind::Game3D, false).kind == ak::RendererKind::Godot);
    CHECK(ak::select_renderer(ak::GameKind::Game3D, false).fell_back);
    CHECK(!ak::select_renderer(ak::GameKind::Game2D, false).fell_back);
    std::printf(fails ? "FAILED\n" : "ALL TESTS PASSED\n");
    return fails;
                  }
