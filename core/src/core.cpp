#include "ak/core.hpp"
#include <algorithm>
#include <numeric>
namespace ak {
Vec3 local_offset(const WorldPos& p, const WorldPos& o) {
    return {float(p.x - o.x), float(p.y - o.y), float(p.z - o.z)};
}
bool needs_rebase(const WorldPos& c, const WorldPos& o, double limit) {
    double dx = c.x - o.x, dy = c.y - o.y, dz = c.z - o.z;
    return dx * dx + dy * dy + dz * dz > limit * limit;
}
void FrameStats::add(double s) { t_.push_back(s); }
double FrameStats::avg_fps() const {
    if (t_.empty()) return 0;
    double sum = std::accumulate(t_.begin(), t_.end(), 0.0);
    return sum > 0 ? t_.size() / sum : 0;
}
double FrameStats::low1_fps() const {
    if (t_.empty()) return 0;
    std::vector<double> v = t_;
    std::sort(v.begin(), v.end(), std::greater<double>());
    size_t n = std::max<size_t>(1, v.size() / 100);
    double sum = std::accumulate(v.begin(), v.begin() + n, 0.0);
    return sum > 0 ? n / sum : 0;
}
}
