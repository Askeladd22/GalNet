#include <x4native.h>

#include <cctype>
#include <cstdint>
#include <string>

namespace
{
static constexpr const char* kBuildTag = "GNNCore hybrid runtime";
constexpr char kMarketCounterKey[] = "gnn_market_counter";
constexpr char kBattleCounterKey[] = "gnn_battle_counter";
constexpr char kLastMarketEmitMsKey[] = "gnn_last_market_emit_ms";
constexpr char kLastBattleEmitMsKey[] = "gnn_last_battle_emit_ms";
constexpr char kBootstrapLuaEvent[] = "gnn.core.bootstrap";
constexpr char kMarketEmitLuaEvent[] = "gnn.market.emit";
constexpr char kMarketLogbookEmitLuaEvent[] = "gnn.market.logbook.emit";
constexpr char kBattleStoryEmitLuaEvent[] = "gnn.battle.story.emit";

int gnn_market_counter = 0;
int gnn_battle_counter = 0;
uint64_t gnn_last_market_emit_ms = 0;
uint64_t gnn_last_battle_emit_ms = 0;

struct MarketNewsCandidate
{
    std::string topic;
    std::string sector;
    int priority = 0;
    bool valid = false;
};

struct MarketNewsPacket
{
    std::string topic;
    std::string sector;
    int priority = 0;
};

struct BattleNewsPacket
{
    std::string type;
    std::string sector;
    std::string faction_a;
    std::string faction_b;
    int severity = 0;
};

MarketNewsCandidate g_pending_market_candidate;

int g_sub_on_game_loaded = 0;
int g_sub_on_game_started = 0;
int g_sub_on_ui_reload = 0;
int g_sub_on_gnn_market_emit = 0;
int g_sub_on_gnn_battle_emit = 0;

void persist_runtime_timestamps();
bool try_open_market_window(uint64_t now_ms, uint64_t cooldown_ms);

void persist_runtime_state()
{
    x4n::stash::set(kMarketCounterKey, gnn_market_counter);
    x4n::stash::set(kBattleCounterKey, gnn_battle_counter);
    persist_runtime_timestamps();
}

void restore_counter(const char* key, int& value, const char* label)
{
    int restored_value = 0;
    if (x4n::stash::get(key, &restored_value)) {
        value = restored_value;
        const std::string message = std::string("[GNNCore] restored ") + label + " = " + std::to_string(value);
        x4n::log::info(message.c_str());
    } else {
        value = 0;
        const std::string message = std::string("[GNNCore] ") + label + " = " + std::to_string(value);
        x4n::log::info(message.c_str());
    }
}

void persist_runtime_timestamps()
{
    x4n::stash::set(kLastMarketEmitMsKey, gnn_last_market_emit_ms);
    x4n::stash::set(kLastBattleEmitMsKey, gnn_last_battle_emit_ms);
}

void clear_pending_market_candidate()
{
    g_pending_market_candidate.topic.clear();
    g_pending_market_candidate.sector.clear();
    g_pending_market_candidate.priority = 0;
    g_pending_market_candidate.valid = false;
}

bool queue_market_candidate(const char* topic, const char* sector, int priority)
{
    if (!topic || !sector) {
        const std::string message = std::string("[GNNCore] market candidate rejected topic=") +
            (topic ? topic : "null") + " sector=" + (sector ? sector : "null") +
            " priority=" + std::to_string(priority);
        x4n::log::info(message.c_str());
        return false;
    }

    MarketNewsCandidate candidate;
    candidate.topic = topic;
    candidate.sector = sector;
    candidate.priority = priority;
    candidate.valid = true;

    if (!g_pending_market_candidate.valid) {
        g_pending_market_candidate = candidate;
        const std::string message = std::string("[GNNCore] market candidate accepted topic=") +
            g_pending_market_candidate.topic + " sector=" + g_pending_market_candidate.sector +
            " priority=" + std::to_string(g_pending_market_candidate.priority);
        x4n::log::info(message.c_str());
        return true;
    }

    if (candidate.priority > g_pending_market_candidate.priority) {
        const int previous_priority = g_pending_market_candidate.priority;
        g_pending_market_candidate = candidate;
        const std::string message = std::string("[GNNCore] market candidate replaced topic=") +
            g_pending_market_candidate.topic + " sector=" + g_pending_market_candidate.sector +
            " priority=" + std::to_string(g_pending_market_candidate.priority) +
            " previous_priority=" + std::to_string(previous_priority);
        x4n::log::info(message.c_str());
        return true;
    }

    const std::string message = std::string("[GNNCore] market candidate discarded topic=") +
        candidate.topic + " sector=" + candidate.sector + " priority=" + std::to_string(candidate.priority) +
        " current_priority=" + std::to_string(g_pending_market_candidate.priority);
    x4n::log::info(message.c_str());
    return false;
}

bool has_pending_market_candidate()
{
    return g_pending_market_candidate.valid;
}

MarketNewsPacket build_market_news_packet(const std::string& topic, const std::string& sector, int priority)
{
    MarketNewsPacket packet;
    packet.topic = topic;
    packet.sector = sector;
    packet.priority = priority;
    return packet;
}

std::string build_market_story_summary(const MarketNewsPacket& packet)
{
    return std::string("topic=") + packet.topic +
        " | sector=" + packet.sector +
        " | priority=" + std::to_string(packet.priority);
}

std::string encode_payload_field(const std::string& value)
{
    static constexpr char kHex[] = "0123456789ABCDEF";

    std::string encoded;
    encoded.reserve(value.size());
    for (unsigned char c : value) {
        if (std::isalnum(c) || c == '-' || c == '_' || c == '.' || c == '~') {
            encoded.push_back(static_cast<char>(c));
        } else {
            encoded.push_back('%');
            encoded.push_back(kHex[(c >> 4) & 0x0F]);
            encoded.push_back(kHex[c & 0x0F]);
        }
    }
    return encoded;
}

std::string build_market_logbook_payload(const MarketNewsPacket& packet)
{
    return std::string("topic_enc=") + encode_payload_field(packet.topic) +
        "|sector_enc=" + encode_payload_field(packet.sector) +
        "|priority=" + std::to_string(packet.priority);
}

BattleNewsPacket build_battle_news_packet(const std::string& type,
                                          const std::string& sector,
                                          const std::string& faction_a,
                                          const std::string& faction_b,
                                          int severity)
{
    BattleNewsPacket packet;
    packet.type = type;
    packet.sector = sector;
    packet.faction_a = faction_a;
    packet.faction_b = faction_b;
    packet.severity = severity;
    return packet;
}

std::string build_battle_logbook_payload(const BattleNewsPacket& packet)
{
    return std::string("type_enc=") + encode_payload_field(packet.type) +
        "|sector_enc=" + encode_payload_field(packet.sector) +
        "|severity=" + std::to_string(packet.severity) +
        "|faction_a_enc=" + encode_payload_field(packet.faction_a) +
        "|faction_b_enc=" + encode_payload_field(packet.faction_b);
}

bool try_emit_pending_market_candidate(uint64_t now_ms, uint64_t cooldown_ms)
{
    if (!has_pending_market_candidate()) {
        x4n::log::info("[GNNCore] no pending market candidate");
        return false;
    }

    if (!try_open_market_window(now_ms, cooldown_ms)) {
        x4n::log::info("[GNNCore] market emit blocked by cooldown");
        return false;
    }

    const std::string message = std::string("[GNNCore] market candidate emitted topic=") +
        g_pending_market_candidate.topic + " sector=" + g_pending_market_candidate.sector +
        " priority=" + std::to_string(g_pending_market_candidate.priority);
    x4n::log::info(message.c_str());
    const std::string payload = g_pending_market_candidate.topic + "|" + g_pending_market_candidate.sector +
        "|" + std::to_string(g_pending_market_candidate.priority);
    const int rc = x4n::raise_lua(kMarketEmitLuaEvent, payload.c_str());
    if (rc != 0) {
        const std::string debug_message = std::string("[GNNCore] market emit lua event raise_lua failed rc=") +
            std::to_string(rc) + " payload=" + payload;
        x4n::log::debug(debug_message.c_str());
    }
    const std::string raised_message = std::string("[GNNCore] market emit lua event raised payload=") + payload;
    x4n::log::info(raised_message.c_str());
    clear_pending_market_candidate();
    return true;
}

void restore_runtime_timestamps()
{
    uint64_t restored_value = 0;
    if (x4n::stash::get(kLastMarketEmitMsKey, &restored_value)) {
        gnn_last_market_emit_ms = restored_value;
    } else {
        gnn_last_market_emit_ms = 0;
    }

    restored_value = 0;
    if (x4n::stash::get(kLastBattleEmitMsKey, &restored_value)) {
        gnn_last_battle_emit_ms = restored_value;
    } else {
        gnn_last_battle_emit_ms = 0;
    }
}

void init_runtime_state()
{
    restore_counter(kMarketCounterKey, gnn_market_counter, "market counter");
    restore_counter(kBattleCounterKey, gnn_battle_counter, "battle counter");
    restore_runtime_timestamps();

    // Seed the stash immediately so a fresh load and a reload share the same keys.
    persist_runtime_state();
}

bool can_emit_market_news_now(uint64_t now_ms, uint64_t cooldown_ms)
{
    if (gnn_last_market_emit_ms == 0) {
        return true;
    }

    return now_ms > gnn_last_market_emit_ms + cooldown_ms;
}

void mark_market_emit_now(uint64_t now_ms)
{
    gnn_last_market_emit_ms = now_ms;
}

uint64_t get_market_cooldown_remaining_ms(uint64_t now_ms, uint64_t cooldown_ms)
{
    if (gnn_last_market_emit_ms == 0) {
        return 0;
    }

    const uint64_t cooldown_ready_ms = gnn_last_market_emit_ms + cooldown_ms;
    if (now_ms > cooldown_ready_ms) {
        return 0;
    }

    return cooldown_ready_ms - now_ms;
}

bool try_open_market_window(uint64_t now_ms, uint64_t cooldown_ms)
{
    if (!can_emit_market_news_now(now_ms, cooldown_ms)) {
        return false;
    }

    mark_market_emit_now(now_ms);
    persist_runtime_timestamps();
    return true;
}

void emit_lua_bootstrap_placeholder(const char* phase)
{
    // Lightweight C++ -> Lua bridge ping for lifecycle diagnostics.
    const int rc = x4n::raise_lua(kBootstrapLuaEvent, phase ? phase : "unknown");
    if (rc != 0) {
        const std::string message = std::string("[GNNCore] raise_lua placeholder returned ") +
            std::to_string(rc) + " for phase=" + (phase ? phase : "unknown");
        x4n::log::debug(message.c_str());
    }
}

void on_game_loaded()
{
    x4n::log::info("[GNNCore] on_game_loaded");
    init_runtime_state();
    clear_pending_market_candidate();
    queue_market_candidate("energy_spike", "Second Contact VII", 10);
    queue_market_candidate("hull_surplus", "Argon Prime", 5);
    queue_market_candidate("factory_shortage", "Hatikvah's Choice I", 20);
    try_emit_pending_market_candidate(5000, 1000);
    x4n::log::info("[GNNCore] battle logbook bridge ready (real source: gnn battle md tracker)");
    ++gnn_market_counter;
    ++gnn_battle_counter;
    persist_runtime_state();
    x4n::log::info("[GNNCore] market counter after load = %d", gnn_market_counter);
    x4n::log::info("[GNNCore] runtime state initialized");
    emit_lua_bootstrap_placeholder("loaded");
}

void on_game_started()
{
    x4n::log::info("[GNNCore] on_game_started");

    emit_lua_bootstrap_placeholder("started");
}

void on_ui_reload()
{
    x4n::log::info("[GNNCore] on_ui_reload");
    persist_runtime_state();
    emit_lua_bootstrap_placeholder("ui_reload");
}

void on_gnn_market_emit(const char* payload)
{
    std::string topic;
    std::string sector;
    std::string priority_text;

    const std::string input = payload ? payload : "";
    size_t start = 0;
    while (start <= input.size()) {
        const size_t end = input.find('|', start);
        const std::string part = input.substr(
            start, end == std::string::npos ? std::string::npos : end - start);

        if (part.rfind("topic=", 0) == 0) {
            topic = part.substr(6);
        } else if (part.rfind("sector=", 0) == 0) {
            sector = part.substr(7);
        } else if (part.rfind("priority=", 0) == 0) {
            priority_text = part.substr(9);
        }

        if (end == std::string::npos) {
            break;
        }
        start = end + 1;
    }

    int priority = 0;
    try {
        if (!priority_text.empty()) {
            priority = std::stoi(priority_text);
        }
    } catch (...) {
        priority = 0;
    }

    const MarketNewsPacket packet = build_market_news_packet(topic, sector, priority);
    const std::string message = std::string("[GNNCore] structured market emit parsed topic=") + packet.topic +
        " sector=" + packet.sector + " priority=" + std::to_string(packet.priority);
    x4n::log::info(message.c_str());

    const std::string summary = build_market_story_summary(packet);
    const std::string story_ready_message = std::string("[GNNCore] market story ready ") + summary;
    x4n::log::info(story_ready_message.c_str());

    const std::string logbook_payload = build_market_logbook_payload(packet);
    const std::string payload_ready_message =
        std::string("[GNNCore] market logbook payload ready = ") + logbook_payload;
    x4n::log::info(payload_ready_message.c_str());

    const int logbook_emit_rc = x4n::raise_lua(kMarketLogbookEmitLuaEvent, logbook_payload.c_str());
    if (logbook_emit_rc != 0) {
        const std::string logbook_emit_message =
            std::string("[GNNCore] market logbook emit raise_lua failed rc=") + std::to_string(logbook_emit_rc);
        x4n::log::debug(logbook_emit_message.c_str());
    }
}

void on_gnn_battle_emit(const char* payload)
{
    std::string type;
    std::string sector;
    std::string faction_a;
    std::string faction_b;
    std::string severity_text;

    const std::string input = payload ? payload : "";
    size_t start = 0;
    while (start <= input.size()) {
        const size_t end = input.find('|', start);
        const std::string part = input.substr(
            start, end == std::string::npos ? std::string::npos : end - start);

        if (part.rfind("type=", 0) == 0) {
            type = part.substr(5);
        } else if (part.rfind("sector=", 0) == 0) {
            sector = part.substr(7);
        } else if (part.rfind("faction_a=", 0) == 0) {
            faction_a = part.substr(10);
        } else if (part.rfind("faction_b=", 0) == 0) {
            faction_b = part.substr(10);
        } else if (part.rfind("severity=", 0) == 0) {
            severity_text = part.substr(9);
        }

        if (end == std::string::npos) {
            break;
        }
        start = end + 1;
    }

    int severity = 0;
    try {
        if (!severity_text.empty()) {
            severity = std::stoi(severity_text);
        }
    } catch (...) {
        severity = 0;
    }

    if (sector.empty() || faction_a.empty() || faction_b.empty()) {
        const std::string skipped_message =
            std::string("[GNNCore] structured battle emit skipped payload=") + input;
        x4n::log::debug(skipped_message.c_str());
        return;
    }

    const BattleNewsPacket packet = build_battle_news_packet(type, sector, faction_a, faction_b, severity);
    const std::string parsed_message = std::string("[GNNCore] structured battle emit parsed type=") + packet.type +
        " sector=" + packet.sector + " faction_a=" + packet.faction_a + " faction_b=" + packet.faction_b +
        " severity=" + std::to_string(packet.severity);
    x4n::log::info(parsed_message.c_str());

    const std::string payload_out = build_battle_logbook_payload(packet);
    const std::string payload_message = std::string("[GNNCore] battle story payload ready = ") + payload_out;
    x4n::log::info(payload_message.c_str());

    const int rc = x4n::raise_lua(kBattleStoryEmitLuaEvent, payload_out.c_str());
    if (rc != 0) {
        const std::string message =
            std::string("[GNNCore] battle logbook emit raise_lua failed rc=") + std::to_string(rc);
        x4n::log::debug(message.c_str());
    }
}

void unsubscribe_events();

void subscribe_events()
{
    unsubscribe_events();

    g_sub_on_game_loaded = x4n::on("on_game_loaded", on_game_loaded);
    g_sub_on_game_started = x4n::on("on_game_started", on_game_started);
    g_sub_on_ui_reload = x4n::on("on_ui_reload", on_ui_reload);
    g_sub_on_gnn_market_emit = x4n::on("on_gnn_market_emit", on_gnn_market_emit);
    g_sub_on_gnn_battle_emit = x4n::on("on_gnn_battle_emit", on_gnn_battle_emit);
}

void unsubscribe_events()
{
    if (g_sub_on_game_loaded != 0) {
        x4n::off(g_sub_on_game_loaded);
        g_sub_on_game_loaded = 0;
    }

    if (g_sub_on_game_started != 0) {
        x4n::off(g_sub_on_game_started);
        g_sub_on_game_started = 0;
    }

    if (g_sub_on_ui_reload != 0) {
        x4n::off(g_sub_on_ui_reload);
        g_sub_on_ui_reload = 0;
    }

    if (g_sub_on_gnn_market_emit != 0) {
        x4n::off(g_sub_on_gnn_market_emit);
        g_sub_on_gnn_market_emit = 0;
    }

    if (g_sub_on_gnn_battle_emit != 0) {
        x4n::off(g_sub_on_gnn_battle_emit);
        g_sub_on_gnn_battle_emit = 0;
    }
}
} // namespace

X4N_EXTENSION
{
    x4n::log::info("[GNNCore] init");
    const std::string build_tag_message = std::string("[GNNCore] build tag = ") + kBuildTag;
    x4n::log::info(build_tag_message.c_str());
    const char* framework_version = x4n::version();
    const std::string framework_version_message =
        std::string("[GNNCore] framework version = ") + (framework_version ? framework_version : "unknown");
    x4n::log::info(framework_version_message.c_str());
    const char* game_version = x4n::game_version();
    const std::string game_version_message =
        std::string("[GNNCore] game version = ") + (game_version ? game_version : "unknown");
    x4n::log::info(game_version_message.c_str());
    const char* extension_path = x4n::path();
    const std::string extension_path_message =
        std::string("[GNNCore] extension path = ") + (extension_path ? extension_path : "unknown");
    x4n::log::info(extension_path_message.c_str());
    subscribe_events();
}

X4N_SHUTDOWN
{
    x4n::log::info("[GNNCore] shutdown");
    persist_runtime_state();
    unsubscribe_events();
}
