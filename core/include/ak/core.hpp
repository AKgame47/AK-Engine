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
