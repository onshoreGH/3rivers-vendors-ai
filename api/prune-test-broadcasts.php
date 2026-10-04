<?php
/**
 * Remove the launch-test broadcasts that the mobile API still shows.
 *
 *   sudo -u www-data php prune-test-broadcasts.php --dry-run
 *   sudo -u www-data php prune-test-broadcasts.php
 *
 * THIS IS A HARD DELETE, and that is not a choice -- it is forced:
 *
 *   - the MySQL `broadcasts` table has NO deleted_at column, and
 *   - BroadcastApiController reads `DB::table('broadcasts')->orderByDesc('id')
 *     ->limit(50)` with no WHERE clause at all.
 *
 * So nothing short of removing the row hides it from the app. The --prune flag
 * on seed-vendor-demo.php soft-deletes via BroadcastRepository, which writes to
 * BiseraDB -- a different store from the one the API reads, which is why those
 * rows never disappeared from the feed.
 *
 * Every row is written to a timestamped JSON file before deletion so the set
 * can be reconstructed. Read the dry run before trusting the id list.
 */

use Illuminate\Support\Facades\DB;

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$dry = in_array('--dry-run', $argv, true);
$say = static fn (string $m) => print("   $m\n");

/**
 * Explicit id list rather than a text match. A pattern like "test" would also
 * catch a legitimate future broadcast about, say, pressure testing; these ids
 * were read off the live feed and confirmed one by one.
 */
const DOOMED = [1, 2, 3, 4, 5, 6, 7, 8, 9];

$rows = DB::table('broadcasts')->whereIn('id', DOOMED)->orderBy('id')->get();

echo "== rows matched ==\n";
foreach ($rows as $r) {
    $a = (array) $r;
    $say(sprintf('%3d  %-28s %s', $a['id'], mb_substr((string) ($a['title'] ?? ''), 0, 28), mb_substr((string) ($a['body'] ?? ''), 0, 40)));
}
$say(sprintf('%d of %d requested ids present', count($rows), count(DOOMED)));

if (count($rows) === 0) {
    echo "\nnothing to do\n";
    exit(0);
}

if ($dry) {
    echo "\n-- DRY RUN: nothing deleted --\n";
    exit(0);
}

// storage/, not /root/: this runs as www-data, which cannot write to root's
// home. The first attempt died here -- correctly, before deleting anything,
// because the backup is taken first on purpose.
$backup = storage_path('app/backups/broadcasts-deleted-' . date('Ymd-His') . '.json');
if (!is_dir(dirname($backup)) && !@mkdir(dirname($backup), 0750, true) && !is_dir(dirname($backup))) {
    fwrite(STDERR, "!! cannot create " . dirname($backup) . " - refusing to delete without a backup\n");
    exit(1);
}
if (file_put_contents($backup, json_encode(array_map(static fn ($r) => (array) $r, $rows->all()), JSON_PRETTY_PRINT)) === false) {
    fwrite(STDERR, "!! could not write $backup - refusing to delete without a backup\n");
    exit(1);
}
$say("backed up to $backup");

$deleted = DB::table('broadcasts')->whereIn('id', DOOMED)->delete();

echo "\n== deleted $deleted rows ==\n";
echo "Restore: re-insert from $backup\n";
