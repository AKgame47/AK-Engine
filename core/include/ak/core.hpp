#pragma once
#include <cstdint>
#include <cmath>
#include <string_view>
#include <vector>
namespace ak {
// Stable 64-bit asset id from a path (FNV-1a). Same input gives same id on every platform.
constexpr uint64_t asset_id(std::string_view s) {
    uint64_t h = 1469598103934665603ull;
    for (char c : s) { h ^= static_cast<unsigned char>(c); h *= 1099511628211ull; }
    return h;
}
// Double-precision world position with float local offset (large-world base).
struct WorldPos { double x = 0, y = 0, z = 0; };
struct Vec3 { float x = 0, y = 0, z = 0; };
Vec3 local_offset(const WorldPos& p, const WorldPos& origin);
// Re-center origin when the camera is more than `limit` metres away.
bool needs_rebase(const WorldPos& camera, const WorldPos& origin, double limit);
// Renderer abstraction (design requirement from AK, 2026-11-27): 2D games use the Godot renderer,
// 3D games use the O3DE (Atom) renderer. The switch is automatic from the game's content.
// O3DE is NOT integrated yet: select_renderer reports a fallback to Godot while it is unavailable.
enum class GameKind { Unknown, Game2D, Game3D };
enum class RendererKind { Godot, O3DE };
struct RendererChoice { RendererKind kind = RendererKind::Godot; bool fell_back = false; };
// Classify a game from counts of 2D-side and 3D-side nodes in its main scene tree.
GameKind classify_game(int nodes_2d, int nodes_3d);
RendererChoice select_renderer(GameKind kind, bool o3de_available);
// Records frame times; reports average and 1% low FPS.
class FrameStats {
public:
    void add(double seconds);
    double avg_fps() const;
    double low1_fps() const;
    size_t count() const { return t_.size(); }
private:
    std::vector<double> t_;
};
}
