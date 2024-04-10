# import pytest
# from fastapi_azure_auth.user import User


# async def mock_user(request):
#     roles = []
#     mark = request.node.get_closet_marker("roles")
#     if mark:
#         roles = mark.args

#     return User(
#         claims={},
#         preferred_username="NormalUser",
#         roles=roles,
#         aud="aud",
#         tid="tid",
#         access_token="123",
#         is_guest=False,
#         iat=1537231048,
#         nbf=1537231048,
#         exp=1537234948,
#         iss="iss",
#         aio="aio",
#         sub="sub",
#         oid="oid",
#         uti="uti",
#         rh="rh",
#         ver="2.0",
#     )


# @pytest.fixture
# def normal_user(request):
#     return mock_user(request)
