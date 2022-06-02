import testinfra

def test_os_release(host):
    assert host.file("/etc/os-release").contains("Fedora")

def test_sshd_inactive(host):
    assert host.service("sshd").is_running is True

def test_nginx_is_installed(host):
    nginx = host.package("nginx")
    assert nginx.is_installed
    assert nginx.version.startswith("1.16.")

def test_nginx_running(host):
    nginx = host.service("nginx")
    assert nginx.is_running

def test_fpm_running(host):
    nginx = host.service("php-fpm")
    assert nginx.is_running

def test_mariadb_running(host):
    nginx = host.service("mariadb")
    assert nginx.is_running
