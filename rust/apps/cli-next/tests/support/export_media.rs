use super::engine::{Catalog, Engine};
use super::*;
use std::collections::BTreeMap;

fn new_engine(server: &mockito::ServerGuard, key: Key, record: Value) -> Engine {
    let id = record["id"].as_i64().unwrap();
    Engine::new(
        server,
        Catalog {
            user: 9007199254740993,
            key,
            albums: BTreeMap::from([(1, "First".into()), (2, "Second".into())]),
            files: BTreeMap::from([((1, id), record.clone()), ((2, id), record)]),
            failed_album: None,
        },
    )
}

fn run(engine: &mut Engine, complete: bool) -> Value {
    let result = engine.run(false, &[]).unwrap();
    assert_eq!(result.complete, complete);
    result.json
}

#[test]
fn engine_preserves_local_media_and_restores_missing_copies() {
    let mut server = mockito::Server::new();
    let key = Key::generate();
    let (file, bytes) = original_fixture(&key, b"original", false, true, 10);
    let fetched = download(&mut server, 10, &bytes, 1);
    let mut engine = new_engine(&server, key, file.clone());
    run(&mut engine, true);
    let root = engine.root();
    let photo = root.join("First/Photo.jpg");
    let sidecar = root.join("First/metadata/Photo.jpg.json");
    let baseline = fs::read(&sidecar).unwrap();
    let hash = read_json(&sidecar)["ente"]["components"][0]["hash"].clone();
    fs::write(&photo, b"embedded EXIF edit").unwrap();
    fs::write(
        root.join("Second/metadata/Photo.jpg.json"),
        b"{\"custom\":true}",
    )
    .unwrap();
    let changed = public(
        file,
        &engine.catalog.key,
        json!({"caption":"current caption"}),
        30,
    );
    engine.catalog.files = BTreeMap::from([((1, 10), changed.clone()), ((2, 10), changed)]);
    for _ in 0..2 {
        let result = run(&mut engine, false);
        assert_eq!(result["conflicts"], 1);
        assert_eq!(
            result["copies"],
            json!({"expected":2,"completed":1,"pending":1})
        );
        assert_eq!(fs::read(&photo).unwrap(), b"embedded EXIF edit");
        assert_eq!(fs::read(&sidecar).unwrap(), baseline);
        assert_eq!(
            engine
                .db()
                .query_row(
                    "SELECT hash FROM components WHERE folder='active:1'",
                    [],
                    |r| r.get::<_, String>(0),
                )
                .unwrap(),
            hash.as_str().unwrap()
        );
        let metadata = read_json(&root.join("Second/metadata/Photo.jpg.json"));
        assert_eq!(metadata["description"], "current caption");
        assert!(metadata.get("custom").is_none());
    }
    fs::remove_file(&photo).unwrap();
    run(&mut engine, true);
    assert_component(&root, "First", "Photo.jpg", b"original");
    fs::write(&photo, b"local edit before removal").unwrap();
    engine.catalog.files.retain(|(album, _), _| *album != 1);
    run(&mut engine, true);
    assert_eq!(
        fs::read(root.join("Trash/First/Photo.jpg")).unwrap(),
        b"local edit before removal"
    );
    assert_eq!(
        read_json(&root.join("Trash/First/metadata/Photo.jpg.json"))["ente"]["components"][0]["hash"],
        hash
    );
    assert_component(&root, "Second", "Photo.jpg", b"original");
    engine.catalog.files.clear();
    run(&mut engine, true);
    assert_component(&root, "Trash/Second", "Photo.jpg", b"original");
    run(&mut engine, true);
    assert_eq!(
        count(
            &engine.db(),
            "SELECT count(*) FROM placements WHERE retained=1"
        ),
        2
    );
    fetched.assert();
}

#[test]
fn engine_checks_previous_bytes_before_source_and_layout_replacement() {
    for (before_live, after_live, hashed) in [
        (false, false, true),
        (false, false, false),
        (true, true, true),
        (false, true, true),
        (true, false, true),
    ] {
        let mut server = mockito::Server::new();
        let key = Key::generate();
        let (old, bytes) = original_fixture(&key, b"old", before_live, hashed, 10);
        let fetched = download(&mut server, 10, &bytes, 1);
        let mut engine = new_engine(&server, key, old);
        run(&mut engine, true);
        fetched.assert();
        fetched.remove();
        let root = engine.root();
        let name = if before_live {
            "Motion.mov"
        } else {
            "Photo.jpg"
        };
        let photo = root.join("First").join(name);
        let modified = fs::metadata(&photo).unwrap().modified().unwrap();
        let baseline = fs::read(root.join("First/metadata").join(format!("{name}.json"))).unwrap();
        fs::write(&photo, b"bad").unwrap();
        fs::File::options()
            .write(true)
            .open(&photo)
            .unwrap()
            .set_modified(modified)
            .unwrap();
        run(&mut engine, true);
        let (new, bytes) = original_fixture(&engine.catalog.key, b"new", after_live, hashed, 30);
        engine.catalog.files = BTreeMap::from([((1, 10), new.clone()), ((2, 10), new)]);
        let fetched = download(&mut server, 10, &bytes, 1);
        let result = run(&mut engine, false);
        assert_eq!(result["conflicts"], 1);
        assert_eq!(result["copies"]["completed"], 1);
        assert_eq!(fs::read(&photo).unwrap(), b"bad");
        assert_eq!(fs::metadata(&photo).unwrap().modified().unwrap(), modified);
        assert_eq!(
            fs::read(root.join("First/metadata").join(format!("{name}.json"))).unwrap(),
            baseline
        );
        if before_live {
            assert_component(&root, "First", "Motion.heic", b"old");
        }
        assert!(!root.join("Trash/First").exists());
        let names: &[&str] = if after_live {
            &["Motion.heic", "Motion.mov"]
        } else {
            &["Photo.jpg"]
        };
        for name in names {
            assert_component(&root, "Second", name, b"new");
        }
        if before_live == after_live {
            fs::write(&photo, b"old").unwrap();
        } else {
            fs::remove_file(&photo).unwrap();
        }
        run(&mut engine, true);
        for name in names {
            assert_component(&root, "First", name, b"new");
        }
        if before_live != after_live {
            assert!(!root.join("Trash/First").join(name).exists());
            assert_eq!(
                read_json(
                    &root
                        .join("Trash/First/metadata")
                        .join(format!("{name}.json"))
                )["ente"]["components"]
                    .as_array()
                    .unwrap()
                    .iter()
                    .find(|component| component["path"] == name)
                    .unwrap()["hash"],
                b64::encode(&hash::hash(b"old", Some(64), None).unwrap())
            );
            if before_live {
                assert_component(&root, "Trash/First", "Motion.heic", b"old");
            }
        }
        fetched.assert();
    }
}

#[test]
fn engine_restores_a_new_layout_after_missing_interrupted_retention() {
    for old_live in [false, true] {
        let mut server = mockito::Server::new();
        let key = Key::generate();
        let (old, bytes) = original_fixture(&key, b"old", old_live, true, 10);
        let fetched = download(&mut server, 10, &bytes, 1);
        let mut engine = new_engine(&server, key, old);
        run(&mut engine, true);
        fetched.assert();
        fetched.remove();
        let db = engine.db();
        db.execute_batch("CREATE TRIGGER stop_retention BEFORE UPDATE ON pending WHEN old.album=1 AND old.retained=1 AND json_type(old.action,'$.Move') IS NOT NULL AND new.action='null' BEGIN SELECT RAISE(ABORT,'stop after retention move'); END;").unwrap();
        let (new, bytes) = original_fixture(&engine.catalog.key, b"new", !old_live, true, 30);
        engine.catalog.files = BTreeMap::from([((1, 10), new.clone()), ((2, 10), new)]);
        let fetched = download(&mut server, 10, &bytes, 2);
        run(&mut engine, false);
        let root = engine.root();
        let old_name = if old_live { "Motion.heic" } else { "Photo.jpg" };
        fs::remove_file(root.join("Trash/First").join(old_name)).unwrap();
        db.execute_batch("DROP TRIGGER stop_retention;").unwrap();
        if old_live {
            fs::write(root.join("First/Motion.mov"), b"local edit").unwrap();
            assert_eq!(run(&mut engine, false)["conflicts"], 1);
            assert_eq!(
                fs::read(root.join("First/Motion.mov")).unwrap(),
                b"local edit"
            );
            assert!(!root.join("First/Photo.jpg").exists());
            fs::remove_file(root.join("First/Motion.mov")).unwrap();
        }
        run(&mut engine, true);
        let new_names: &[&str] = if old_live {
            &["Photo.jpg"]
        } else {
            &["Motion.heic", "Motion.mov"]
        };
        for folder in ["First", "Second"] {
            for name in new_names {
                assert_component(&root, folder, name, b"new");
            }
        }
        assert!(!root.join("Trash/First").join(old_name).exists());
        assert_eq!(
            read_json(
                &root
                    .join("Trash/First/metadata")
                    .join(format!("{old_name}.json"))
            )["ente"]["components"][0]["hash"],
            b64::encode(&hash::hash(b"old", Some(64), None).unwrap())
        );
        assert_eq!(run(&mut engine, true)["changes"]["retained"], 0);
        assert_eq!(
            count(
                &db,
                "SELECT count(*) FROM placements WHERE album=1 AND retained=1"
            ),
            1
        );
        fetched.assert();
    }
}

#[test]
fn engine_checks_both_live_components_when_only_one_source_component_changes() {
    let mut server = mockito::Server::new();
    let key = Key::generate();
    let (old, bytes) = original_fixture(&key, b"old", true, true, 10);
    let fetched = download(&mut server, 10, &bytes, 1);
    let mut engine = new_engine(&server, key, old);
    run(&mut engine, true);
    fetched.assert();
    fetched.remove();
    let root = engine.root();
    let photo = root.join("First/Motion.heic");
    let modified = fs::metadata(&photo).unwrap().modified().unwrap();
    fs::write(&photo, b"bad").unwrap();
    fs::File::options()
        .write(true)
        .open(&photo)
        .unwrap()
        .set_modified(modified)
        .unwrap();
    let mut archive = zip::ZipWriter::new(std::io::Cursor::new(Vec::new()));
    for (name, bytes) in [("image.heic", b"old"), ("video.mov", b"new")] {
        archive
            .start_file(name, zip::write::SimpleFileOptions::default())
            .unwrap();
        archive.write_all(bytes).unwrap();
    }
    let archive = archive.finish().unwrap().into_inner();
    let (mut new, bytes) = source(10, &engine.catalog.key, &archive, "Motion.heic");
    let image = b64::encode(&hash::hash(b"old", Some(64), None).unwrap());
    let video = b64::encode(&hash::hash(b"new", Some(64), None).unwrap());
    let metadata = blob::encrypt_json(
        &json!({"title":"Motion.heic","fileType":2,"creationTime":1_700_000_000_123_456i64,"hash":format!("{image}:{video}")}),
        &file_key(&new, &engine.catalog.key),
    ).unwrap();
    new["metadata"] = json!({"encryptedData":b64::encode(&metadata.encrypted_data),"decryptionHeader":b64::encode(metadata.decryption_header.as_bytes())});
    let new = revision(new, 30);
    engine.catalog.files = BTreeMap::from([((1, 10), new.clone()), ((2, 10), new)]);
    let fetched = download(&mut server, 10, &bytes, 1);
    assert_eq!(run(&mut engine, false)["conflicts"], 1);
    assert_eq!(fs::read(&photo).unwrap(), b"bad");
    assert_component(&root, "First", "Motion.mov", b"old");
    assert_component(&root, "Second", "Motion.heic", b"old");
    assert_component(&root, "Second", "Motion.mov", b"new");
    fs::write(&photo, b"old").unwrap();
    run(&mut engine, true);
    assert_component(&root, "First", "Motion.heic", b"old");
    assert_component(&root, "First", "Motion.mov", b"new");
    fetched.assert();
}

#[test]
fn engine_recovery_checks_live_siblings_before_acknowledging_publication() {
    let mut server = mockito::Server::new();
    let key = Key::generate();
    let (old, bytes) = original_fixture(&key, b"old", true, true, 10);
    let fetched = download(&mut server, 10, &bytes, 1);
    let mut engine = new_engine(&server, key, old);
    run(&mut engine, true);
    fetched.assert();
    fetched.remove();
    let db = engine.db();
    db.execute_batch("CREATE TRIGGER stop_ack BEFORE UPDATE ON pending WHEN old.album=1 AND json_extract(old.action,'$.Publish.output.Media.role')='image' AND new.action='null' BEGIN SELECT RAISE(ABORT,'stop after image publication'); END;").unwrap();
    let (new, bytes) = original_fixture(&engine.catalog.key, b"new", true, true, 30);
    engine.catalog.files = BTreeMap::from([((1, 10), new.clone()), ((2, 10), new)]);
    let fetched = download(&mut server, 10, &bytes, 2);
    run(&mut engine, false);
    let root = engine.root();
    assert_eq!(fs::read(root.join("First/Motion.heic")).unwrap(), b"new");
    fs::write(root.join("First/Motion.mov"), b"edited video").unwrap();
    let pending: String = db
        .query_row(
            "SELECT action FROM pending WHERE album=1 AND file=10",
            [],
            |r| r.get(0),
        )
        .unwrap();
    db.execute_batch("DROP TRIGGER stop_ack;").unwrap();
    let result = run(&mut engine, false);
    assert_eq!(result["conflicts"], 1);
    assert_eq!(
        fs::read(root.join("First/Motion.mov")).unwrap(),
        b"edited video"
    );
    assert_eq!(
        db.query_row(
            "SELECT action FROM pending WHERE album=1 AND file=10",
            [],
            |r| r.get::<_, String>(0)
        )
        .unwrap(),
        pending
    );
    assert_component(&root, "Second", "Motion.heic", b"new");
    assert_component(&root, "Second", "Motion.mov", b"new");
    fs::remove_file(root.join("First/Motion.mov")).unwrap();
    run(&mut engine, true);
    assert_component(&root, "First", "Motion.heic", b"new");
    assert_component(&root, "First", "Motion.mov", b"new");
    fetched.assert();
}

#[test]
fn engine_recovery_preserves_edits_at_either_move_endpoint() {
    for (moved, removed) in [(false, false), (true, false), (false, true), (true, true)] {
        let mut server = mockito::Server::new();
        let key = Key::generate();
        let (file, bytes) = original_fixture(&key, b"original", false, true, 10);
        let fetched = download(&mut server, 10, &bytes, 1);
        let mut engine = new_engine(&server, key, file.clone());
        run(&mut engine, true);
        let db = engine.db();
        db.execute_batch("CREATE TRIGGER stop_move BEFORE UPDATE ON pending WHEN old.album=1 AND json_type(old.action,'$.Move') IS NOT NULL AND new.action='null' BEGIN SELECT RAISE(ABORT,'stop after media move'); END;").unwrap();
        let renamed = public(
            file,
            &engine.catalog.key,
            json!({"editedName":"Renamed.jpg"}),
            30,
        );
        engine.catalog.files = BTreeMap::from([((1, 10), renamed.clone()), ((2, 10), renamed)]);
        run(&mut engine, false);
        let root = engine.root();
        let old = root.join("First/Photo.jpg");
        let new = root.join("First/Renamed.jpg");
        if !moved {
            fs::rename(&new, &old).unwrap();
        }
        let changed = if moved { &new } else { &old };
        fs::write(changed, b"local edit").unwrap();
        db.execute_batch("DROP TRIGGER stop_move;").unwrap();
        if removed {
            engine.catalog.files.retain(|(album, _), _| *album != 1);
            run(&mut engine, true);
            assert_eq!(
                fs::read(root.join("Trash/First/Photo.jpg")).unwrap(),
                b"local edit"
            );
            assert_eq!(
                read_json(&root.join("Trash/First/metadata/Photo.jpg.json"))["ente"]["components"]
                    [0]["hash"],
                b64::encode(&hash::hash(b"original", Some(64), None).unwrap())
            );
            assert_component(&root, "Second", "Renamed.jpg", b"original");
            fetched.assert();
            continue;
        }
        let result = run(&mut engine, false);
        assert_eq!(result["conflicts"], 1);
        assert_eq!(fs::read(changed).unwrap(), b"local edit");
        assert_component(&root, "Second", "Renamed.jpg", b"original");
        assert_eq!(
            read_json(&root.join("First/metadata/Photo.jpg.json"))["ente"]["components"][0]["hash"],
            b64::encode(&hash::hash(b"original", Some(64), None).unwrap())
        );
        fs::write(changed, b"original").unwrap();
        run(&mut engine, true);
        assert_component(&root, "First", "Renamed.jpg", b"original");
        fetched.assert();
    }
}

fn linked(root: &Path, first: &str, second: &str) -> bool {
    same_file::is_same_file(root.join(first), root.join(second)).unwrap()
}

#[test]
fn engine_consolidates_copies_and_keeps_linked_history() {
    let mut server = mockito::Server::new();
    let key = Key::generate();
    let (record, bytes) = original_fixture(&key, b"old", false, true, 10);
    let fetched = download(&mut server, 10, &bytes, 1);
    let mut other = public(record.clone(), &key, json!({"editedName":"Other.jpg"}), 20);
    other["id"] = json!(11);
    let separate = download(&mut server, 11, &bytes, 1);
    let mut engine = new_engine(&server, key, record.clone());
    engine.catalog.files.insert((2, 11), other);
    engine.catalog.albums.insert(3, "Excluded".into());
    engine.catalog.files.insert((3, 10), record.clone());
    run(&mut engine, true);
    let root = engine.root();
    let first = root.join("First/Photo.jpg");
    let second = root.join("Second/Photo.jpg");
    assert!(!same_file::is_same_file(&first, &second).unwrap());
    let permissions = fs::metadata(&first).unwrap().permissions();
    let mut readonly = permissions.clone();
    readonly.set_readonly(true);
    fs::set_permissions(&first, readonly).unwrap();
    engine.hardlinks = true;
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let directory = root.join("Second");
        let permissions = fs::metadata(&directory).unwrap().permissions();
        fs::set_permissions(&directory, fs::Permissions::from_mode(0o500)).unwrap();
        let probe = directory.join("permission-probe");
        let result = fs::hard_link(&first, &probe)
            .is_err()
            .then(|| engine.run(false, &["First", "Second"]));
        fs::set_permissions(&directory, permissions).unwrap();
        if let Some(result) = result {
            let result = result.unwrap();
            assert!(!result.complete);
            assert_eq!(result.json["copies"]["completed"], 2);
            assert_eq!(fs::read(&second).unwrap(), b"old");
            assert!(!same_file::is_same_file(&first, &second).unwrap());
        } else {
            fs::remove_file(probe).unwrap();
            eprintln!(
                "skipping permission failure: directory permissions do not prevent hard links"
            );
        }
    }
    assert_eq!(run(&mut engine, true)["changes"]["exported"], 2);
    assert!(same_file::is_same_file(&first, &second).unwrap());
    assert!(!same_file::is_same_file(&first, root.join("Second/Other.jpg")).unwrap());
    assert_eq!(run(&mut engine, true)["changes"]["exported"], 0);
    assert!(fs::metadata(&second).unwrap().permissions().readonly());
    fs::set_permissions(&first, permissions).unwrap();
    assert_eq!(count(&engine.db(), "SELECT count(*) FROM temporaries"), 0);
    for album in ["First", "Second"] {
        for entry in fs::read_dir(root.join(album)).unwrap() {
            let name = entry.unwrap().file_name();
            assert!(!name.to_string_lossy().ends_with(".part"));
        }
    }
    engine.catalog.files.remove(&(1, 10));
    run(&mut engine, true);
    let retained = root.join("Trash/First/Photo.jpg");
    assert!(same_file::is_same_file(&retained, &second).unwrap());
    let history_path = root.join("Trash/First/metadata/Photo.jpg.json");
    let history = fs::read(&history_path).unwrap();
    let before = fs::metadata(&retained).unwrap().modified().unwrap();
    engine.hardlinks = false;
    let changed = public(
        record,
        &engine.catalog.key,
        json!({"editedTime":1_700_000_100_000_000i64}),
        30,
    );
    engine.catalog.files.insert((2, 10), changed);
    assert!(engine.run(false, &["Second"]).unwrap().complete);
    assert_ne!(fs::metadata(&retained).unwrap().modified().unwrap(), before);
    assert!(same_file::is_same_file(&retained, &second).unwrap());
    let (new, bytes) = original_fixture(&engine.catalog.key, b"new", false, true, 40);
    engine.catalog.files.insert((2, 10), new.clone());
    let replacement = download(&mut server, 10, &bytes, 1);
    assert!(engine.run(false, &["Second"]).unwrap().complete);
    assert_eq!(fs::read(&retained).unwrap(), b"old");
    assert_eq!(fs::read(&history_path).unwrap(), history);
    assert_eq!(fs::read(root.join("Excluded/Photo.jpg")).unwrap(), b"old");
    engine.catalog.files.insert((1, 10), new);
    assert!(engine.run(false, &["First", "Second"]).unwrap().complete);
    assert_component(&root, "First", "Photo.jpg", b"new");
    assert!(!same_file::is_same_file(&first, &second).unwrap());
    fetched.assert();
    separate.assert();
    replacement.assert();
}

#[test]
fn engine_links_live_components_and_preserves_edits() {
    let mut server = mockito::Server::new();
    let key = Key::generate();
    let (record, bytes) = original_fixture(&key, b"original", true, true, 10);
    let fetched = download(&mut server, 10, &bytes, 1);
    let mut engine = new_engine(&server, key, record);
    engine.hardlinks = true;
    run(&mut engine, true);
    let root = engine.root();
    for name in ["Motion.heic", "Motion.mov"] {
        assert!(linked(
            &root,
            &format!("First/{name}"),
            &format!("Second/{name}")
        ));
        assert!(!linked(
            &root,
            &format!("First/metadata/{name}.json"),
            &format!("Second/metadata/{name}.json")
        ));
        assert_component(&root, "Second", name, b"original");
    }
    assert!(!linked(&root, "First/Motion.heic", "First/Motion.mov"));
    let first = root.join("First/Motion.heic");
    let second = root.join("Second/Motion.heic");
    fs::remove_file(&first).unwrap();
    assert_eq!(fs::read(&second).unwrap(), b"original");
    run(&mut engine, true);
    assert!(same_file::is_same_file(&first, &second).unwrap());
    fs::write(&first, b"edited in place").unwrap();
    let (other, bytes) = source(11, &engine.catalog.key, b"independent", "Other.jpg");
    engine.catalog.files.insert((2, 11), other);
    let independent = download(&mut server, 11, &bytes, 1);
    let result = run(&mut engine, false);
    assert_eq!(result["conflicts"], 2);
    assert_eq!(result["copies"]["completed"], 1);
    assert_component(&root, "Second", "Other.jpg", b"independent");
    assert_eq!(fs::read(&second).unwrap(), b"edited in place");
    fs::remove_file(&first).unwrap();
    fs::write(&first, b"independent local edit").unwrap();
    assert_eq!(run(&mut engine, false)["conflicts"], 2);
    assert_eq!(fs::read(&first).unwrap(), b"independent local edit");
    independent.assert();
    fetched.assert();
}

#[test]
fn engine_recovers_interrupted_link_publication() {
    for boundary in [
        "BEFORE INSERT ON pending WHEN new.album=2 AND json_type(new.action,'$.Publish.output.Media') IS NOT NULL",
        "BEFORE UPDATE ON pending WHEN old.album=2 AND json_type(old.action,'$.Publish.output.Media') IS NOT NULL AND new.action='null'",
        "BEFORE UPDATE ON components WHEN new.folder='active:2' AND old.intended_time IS NULL AND new.intended_time IS NOT NULL",
    ] {
        let mut server = mockito::Server::new();
        let key = Key::generate();
        let (record, bytes) = original_fixture(&key, b"original", false, true, 10);
        let fetched = download(&mut server, 10, &bytes, 1);
        let mut engine = new_engine(&server, key, record);
        run(&mut engine, true);
        engine.hardlinks = true;
        let db = engine.db();
        db.execute_batch(&format!("CREATE TRIGGER stop_link {boundary} BEGIN SELECT RAISE(ABORT,'link publication interrupted'); END;")).unwrap();
        run(&mut engine, false);
        let root = engine.root();
        assert_eq!(
            fs::read(root.join("Second/Photo.jpg")).unwrap(),
            b"original"
        );
        db.execute_batch("DROP TRIGGER stop_link").unwrap();
        if boundary.contains("ON components") {
            let photo = root.join("Second/Photo.jpg");
            let modified = fs::metadata(&photo).unwrap().modified().unwrap();
            fs::write(&photo, b"modified").unwrap();
            fs::File::options()
                .write(true)
                .open(&photo)
                .unwrap()
                .set_modified(modified)
                .unwrap();
            engine.hardlinks = false;
            for _ in 0..2 {
                let result = engine.run(false, &["Second"]).unwrap();
                assert!(!result.complete);
                assert_eq!(result.json["conflicts"], 1);
            }
            assert_eq!(fs::read(&photo).unwrap(), b"modified");
            fs::write(&photo, b"original").unwrap();
            engine.hardlinks = true;
        }
        run(&mut engine, true);
        assert!(linked(&root, "First/Photo.jpg", "Second/Photo.jpg"));
        assert_eq!(count(&db, "SELECT count(*) FROM temporaries"), 0);
        fetched.assert();
    }
}

#[test]
fn engine_rechecks_link_source_before_completion() {
    use std::time::{Duration, UNIX_EPOCH};
    let mut server = mockito::Server::new();
    let key = Key::generate();
    let (record, bytes) = original_fixture(&key, b"original", false, true, 10);
    let fetched = download(&mut server, 10, &bytes, 1);
    let mut engine = new_engine(&server, key, record.clone());
    for (id, name) in [(3, "Third"), (4, "Fourth")] {
        engine.catalog.albums.insert(id, name.into());
        engine.catalog.files.insert((id, 10), record.clone());
    }
    run(&mut engine, true);
    let root = engine.root();
    let first = root.join("First/Photo.jpg");
    fs::remove_file(root.join("Fourth/Photo.jpg")).unwrap();
    fs::hard_link(&first, root.join("Fourth/Photo.jpg")).unwrap();
    let changed = public(
        record,
        &engine.catalog.key,
        json!({"editedTime":1_700_000_100_000_000i64}),
        30,
    );
    for record in engine.catalog.files.values_mut() {
        *record = changed.clone();
    }
    let modified = UNIX_EPOCH + Duration::from_secs(1_700_000_100);
    engine.hardlinks = true;
    let export = engine.prepare(engine.options(false, &[])).unwrap();
    let blocked = root.join("Third/metadata/Photo.jpg.json");
    fs::remove_file(&blocked).unwrap();
    fs::create_dir(&blocked).unwrap();
    let result = engine.execute_with_report(export, &|line| {
        eprintln!("{line}");
        if line.starts_with("file:3:10:") && line.contains("expected a regular file") {
            assert!(linked(&root, "First/Photo.jpg", "Second/Photo.jpg"));
            assert_eq!(fs::metadata(&first).unwrap().modified().unwrap(), modified);
            fs::write(&first, b"modified").unwrap();
            fs::File::options()
                .write(true)
                .open(&first)
                .unwrap()
                .set_modified(modified + Duration::from_secs(1))
                .unwrap();
        }
    });
    let result = result.unwrap();
    assert!(!result.complete);
    assert_eq!(result.json["conflicts"], 2);
    assert_eq!(result.json["copies"]["completed"], 2);
    assert_eq!(fs::read(&first).unwrap(), b"modified");
    assert_eq!(
        fs::metadata(&first).unwrap().modified().unwrap(),
        modified + Duration::from_secs(1)
    );
    let result = engine.run(false, &["First", "Second", "Fourth"]).unwrap();
    assert!(!result.complete);
    assert_eq!(result.json["conflicts"], 3);
    assert_eq!(result.json["copies"]["completed"], 0);
    fetched.assert();
}
