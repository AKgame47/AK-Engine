// SPDX-License-Identifier: GPL-3.0-only
#include "register_types.h"

#include "ak_core_bridge.h"
#include "core/object/class_db.h"

void initialize_ak_core_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
	GDREGISTER_CLASS(AKCore);
	GDREGISTER_CLASS(AKFrameStats);
}

void uninitialize_ak_core_module(ModuleInitializationLevel p_level) {
}
