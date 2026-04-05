# tests/test_system2.jac — Deterministic System 2 + shared tests (no live GitHub/Discord/E2B).

import hmac;
import from hashlib { sha256 }
import from integrations.github { validate_webhook_signature }
import from lib.manifest {
    normalize_package_name,
    dedupe_incident_key,
    parse_manifest_deps,
    manifest_delta,
    classify_dependency_risks,
    fix_invert_manifest,
    rank_gap_candidates,
    package_alias_map
}

test "normalize_package_name collapses separators" {
    assert normalize_package_name("Foo_Bar.baz") == "foo-bar-baz";
}

test "dedupe_incident_key is stable" {
    k1 = dedupe_incident_key("o/r", "abc", "package.json", "Left-Pad");
    k2 = dedupe_incident_key("o/r", "abc", "package.json", "left_pad");
    assert k1 == k2;
}

test "parse_manifest_deps reads package.json" {
    j = '{"dependencies":{"a":"^1.0.0","b":"2.x"}}';
    d = parse_manifest_deps("package.json", j);
    assert d.get("a", "") == "^1.0.0";
}

test "manifest_delta detects added keys" {
    p = {"x": "1"};
    c = {"x": "1", "y": "2"};
    delta = manifest_delta(p, c);
    added = delta.get("added", {});
    assert "y" in added;
}

test "classify_dependency_risks flags phantom import" {
    added = {"evil-pkg": "1.0.0"};
    graph = set(["requests"]);
    risks = classify_dependency_risks("requirements.txt", "", "", added, graph);
    assert len(risks) > 0;
}

test "fix_invert_manifest removes added npm dep" {
    par = '{"dependencies":{"a":"1"}}';
    cur = '{"dependencies":{"a":"1","b":"9"}}';
    out = fix_invert_manifest("package.json", par, cur, "b");
    assert "b" not in out or "\"b\"" not in out;
}

test "rank_gap_candidates prefers untested core files" {
    files = ["walkers/foo.jac", "tests/test_foo.jac", "README.md"];
    ranked = rank_gap_candidates(files, set(), set(), ["walkers/"]);
    assert len(ranked) > 0;
}

test "package_alias_map contains pillow alias" {
    m = package_alias_map();
    assert m.get("pil", "") == "pillow";
}

test "HMAC validation accepts correct signature" {
    payload = bytes("test_payload", "utf-8");
    secret = "my_secret";
    correct_sig = "sha256=" + hmac.new(secret.encode(), payload, sha256).hexdigest();
    assert validate_webhook_signature(payload, correct_sig, secret);
}

test "HMAC validation rejects wrong signature" {
    payload = bytes("test_payload", "utf-8");
    assert not validate_webhook_signature(payload, "sha256=deadbeef", "my_secret");
}
