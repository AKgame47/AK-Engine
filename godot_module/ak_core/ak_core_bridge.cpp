// SPDX-License-Identifier: GPL-3.0-only
#include "ak_core_bridge.h"

#include "core/object/class_db.h"
#include "core/object/method_bind.h"

#include <string_view>

int64_t AKCore::asset_id(const String &p_path) {
	CharString cs = p_path.utf8();
	return (int64_t)ak::asset_id(std::string_view(cs.get_data(), cs.length()));
}

bool AKCore::needs_rebase(double cx, double cy, double cz, double ox, double oy, double oz, double p_limit) {
	return ak::needs_rebase(ak::WorldPos{ cx, cy, cz }, ak::WorldPos{ ox, oy, oz }, p_limit);
}

String AKCore::get_version() {
	return "AK Core 0.0.1";
}

static void _count_nodes(Node *p_node, int &n2, int &n3) {
	if (p_node->is_class("Node3D")) {
		n3++;
	} else if (p_node->is_class("CanvasItem")) {
		n2++;
	}
	for (int i = 0; i < p_node->get_child_count(); i++) {
		_count_nodes(p_node->get_child(i), n2, n3);
	}
}

String AKCore::detect_game_kind(Node *p_root) {
	ERR_FAIL_NULL_V(p_root, "unknown");
	int n2 = 0, n3 = 0;
	_count_nodes(p_root, n2, n3);
	switch (ak::classify_game(n2, n3)) {
		case ak::GameKind::Game2D:
			return "2d";
		case ak::GameKind::Game3D:
			return "3d";
		default:
			return "unknown";
	}
}

static ak::GameKind _kind_from(const String &s) {
	if (s == "2d") {
		return ak::GameKind::Game2D;
	}
	if (s == "3d") {
		return ak::GameKind::Game3D;
	}
	return ak::GameKind::Unknown;
}

String AKCore::select_renderer(const String &p_game_kind, bool p_o3de_available) {
	return ak::select_renderer(_kind_from(p_game_kind), p_o3de_available).kind == ak::RendererKind::O3DE ? "o3de" : "godot";
}

bool AKCore::renderer_is_fallback(const String &p_game_kind, bool p_o3de_available) {
	return ak::select_renderer(_kind_from(p_game_kind), p_o3de_available).fell_back;
}

void AKCore::_bind_methods() {
	ClassDB::bind_static_method("AKCore", D_METHOD("detect_game_kind", "root"), &AKCore::detect_game_kind);
	ClassDB::bind_static_method("AKCore", D_METHOD("select_renderer", "game_kind", "o3de_available"), &AKCore::select_renderer);
	ClassDB::bind_static_method("AKCore", D_METHOD("renderer_is_fallback", "game_kind", "o3de_available"), &AKCore::renderer_is_fallback);
	ClassDB::bind_static_method("AKCore", D_METHOD("asset_id", "path"), &AKCore::asset_id);
	ClassDB::bind_static_method("AKCore", D_METHOD("needs_rebase", "cx", "cy", "cz", "ox", "oy", "oz", "limit"), &AKCore::needs_rebase);
	ClassDB::bind_static_method("AKCore", D_METHOD("get_version"), &AKCore::get_version);
}

void AKFrameStats::add(double p_seconds) {
	stats.add(p_seconds);
}

double AKFrameStats::avg_fps() const {
	return stats.avg_fps();
}

double AKFrameStats::low1_fps() const {
	return stats.low1_fps();
}

int AKFrameStats::get_count() const {
	return (int)stats.count();
}

void AKFrameStats::_bind_methods() {
	ClassDB::bind_method(D_METHOD("add", "seconds"), &AKFrameStats::add);
	ClassDB::bind_method(D_METHOD("avg_fps"), &AKFrameStats::avg_fps);
	ClassDB::bind_method(D_METHOD("low1_fps"), &AKFrameStats::low1_fps);
	ClassDB::bind_method(D_METHOD("get_count"), &AKFrameStats::get_count);
}
