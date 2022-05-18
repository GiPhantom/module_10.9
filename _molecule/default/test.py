import pytest
import testinfra

def test_os_release(host):
    assert host.file ("/etc/os-release").contains("Ubuntu")

def test_nginx_is_installed(host):
    nginx = host.package("nginx")
    assert nginx.is_installed
    assert nginx.version.startswith("1.16.1")

#def test_socket_listening(host):
#     assert host.socket('tsp://0.0.0.0:8080).is_listening
#     ip = host.interface('eth0').addresses[0]
#     response = requests.get('http://{}'.format(ip))
#     assert response.status_code ==200 
