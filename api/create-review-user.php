<?php
/**
 * Create the App Store reviewer account for the 3Rivers Vendors mobile app.
 *
 *   cd /srv/apps/3rivers-v/var/www/3riversv
 *   REVIEW_EMAIL='...' REVIEW_PASSWORD='...' sudo -E -u www-data php create-review-user.php --dry-run
 *   REVIEW_EMAIL='...' REVIEW_PASSWORD='...' sudo -E -u www-data php create-review-user.php
 *
 * Credentials come from the environment, never from source or argv: a literal
 * in this file would end up in git, and argv is world-readable via ps(1) while
 * the script runs.
 *
 * Identity for this app is split across two stores and BOTH halves are
 * required -- with only the first, login succeeds and then every screen 403s:
 *   - the user row lives in SQLite (User::$connection = 'sqlite')
 *   - the RBAC mapping lives in BiseraDB (rbac_roles / rbac_permissions /
 *     rbac_role_permissions / rbac_user_roles)
 *
 * The account is deliberately given a NON-privileged role. RequirePermission
 * short-circuits for roles keyed 'owner' or 'admin', which would hand an Apple
 * reviewer api.users.delete and api.invoices.delete against production data.
 * This grants exactly what the app reads, plus broadcasts.write so read
 * receipts work and devices.register for push enrolment. No delete anywhere.
 *
 * Hashing goes through the framework's own Hash facade so the stored format
 * cannot drift from what Hash::check() expects at login.
 */

use App\BiseraDb\BiseraDbClient;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$email = getenv('REVIEW_EMAIL') ?: '';
$password = getenv('REVIEW_PASSWORD') ?: '';
if ($email === '' || $password === '') {
    fwrite(STDERR, "!! set REVIEW_EMAIL and REVIEW_PASSWORD in the environment\n");
    exit(1);
}

const NAME = 'Apple App Review';
const ROLE_KEY = 'app_review';
const ROLE_NAME = 'App Review (read-only)';

/** Exactly what the mobile app exercises -- nothing that can destroy data. */
const PERMISSIONS = [
    'api.devices.register',
    'api.broadcasts.read',
    'api.broadcasts.write',
    'api.financials.read',
    'api.invoices.read',
    'api.expenses.read',
    'api.payments.read',
    'api.products.read',
];

$dryRun = in_array('--dry-run', $argv, true);
$say = static fn (string $m) => print("   $m\n");

echo "== 1. user row (SQLite) ==\n";
$user = User::where('email', $email)->first();
$say($user ? "exists: id={$user->id} -- password will be reset" : 'does not exist -- will create');
if (!$dryRun) {
    $user = User::updateOrCreate(
        ['email' => $email],
        [
            'name' => NAME,
            'password' => Hash::make($password),
            'role' => 'vendor',
            'email_verified_at' => now(),
        ],
    );
    $say("ok: id={$user->id}");
}
if (!$user) {
    $say('(dry run -- no user id yet, stopping before RBAC)');
    exit(0);
}

/** @var BiseraDbClient $db */
$db = app(BiseraDbClient::class);

echo "== 2. role (BiseraDB rbac_roles) ==\n";
$role = $db->getByField('rbac_roles', 'key', ROLE_KEY);
if ($role) {
    $say("exists: id={$role['id']}");
} else {
    $say('missing -- creating a NON-privileged role (deliberately not owner/admin)');
    if (!$dryRun) {
        $roleId = $db->nextId('rbac_roles');
        $role = ['id' => $roleId, 'key' => ROLE_KEY, 'name' => ROLE_NAME];
        $db->upsert('rbac_roles', (string) $roleId, $role);
        $say("created: id=$roleId");
    }
}

echo "== 3. role -> permission mappings ==\n";
foreach (PERMISSIONS as $key) {
    $perm = $db->getByField('rbac_permissions', 'key', $key);
    if (!$perm) {
        $say("!! '$key' is not in rbac_permissions - SKIPPED (that screen will 403)");
        continue;
    }
    if ($dryRun || !$role) {
        $say("would grant $key");
        continue;
    }
    // compound key: this collection has no single id column
    $db->upsert(
        'rbac_role_permissions',
        $role['id'] . '-' . $perm['id'],
        ['role_id' => $role['id'], 'permission_id' => $perm['id']],
    );
    $say("granted $key");
}

echo "== 4. user -> role mapping ==\n";
if ($dryRun || !$role) {
    $say('would map the user to ' . ROLE_KEY);
} else {
    $db->upsert(
        'rbac_user_roles',
        $user->id . '-' . $role['id'],
        ['user_id' => $user->id, 'role_id' => $role['id']],
    );
    $say("mapped user {$user->id} -> role {$role['id']}");
}

echo "\n" . ($dryRun ? "-- DRY RUN: nothing was written --\n" : "== done ==\n");
echo "Verify (substitute the same credentials):\n";
echo "  curl -s -H 'Accept: application/json' -H 'Content-Type: application/json' \\\n";
echo "    -X POST https://3rivers-v.onshoretech.ai/api/auth/login \\\n";
echo "    -d '{\"login\":\"<email>\",\"password\":\"<password>\",\"device_name\":\"probe\"}'\n";
