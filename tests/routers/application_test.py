def test_no_data_returns_400(client):
    response = client.get("/application/94ae7aab-6bd0-4c88-9d9a-9b82859293a4")
    assert response.status_code == 400


def test_data_returns_200(client, seed_application):
    response = client.get(f"/application/{seed_application}")
    assert response.status_code == 200
