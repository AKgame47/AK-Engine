// SPDX-License-Identifier: GPL-3.0-only
// AK Engine: exposes AK Core (core/include/ak/core.hpp) to GDScript and C++ as engine classes.
#pragma once

#include "core/object/ref_counted.h"
#include "scene/main/node.h"
#include "ak/core.hpp"

class AKCore : public RefCounted {
	GDCLASS(AKCore, RefCounted);

protected:
	static void _bind_methods();

public:
	static int64_t asset_id(const String &p_path);
	static bool needs_rebase(double cx, double cy, double cz, double ox, double oy, double oz, double p_limit);
	static String get_version();
	// Renderer switch (AK requirement): returns "godot" or "o3de". O3DE is not integrated, so a 3D game gets "godot" and is_fallback() is true.
	static String detect_game_kind(Node *p_root);
	static String select_renderer(const String &p_game_kind, bool p_o3de_available);
	static bool renderer_is_fallback(const String &p_game_kind, bool p_o3de_available);
};

class AKFrameStats : public RefCounted {
	GDCLASS(AKFrameStats, RefCounted);
	ak::FrameStats stats;

protected:
	static void _bind_methods();

public:
	void add(double p_seconds);
	double avg_fps() const;
	double low1_fps() const;
	int get_count() const;
};
