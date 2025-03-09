import http.client
import os


def a(a: str) -> int:
    http.client.HTTPSConnection("api.open-meteo.com")
    return a


if __name__ == "__main__":
    a(2)
