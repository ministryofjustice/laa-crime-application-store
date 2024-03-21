from typing import List

from laa_crime_application_store_app.models.application_schema import Application


class Permissions:
    LOCKED_STATES = "granted"
    CASEWORKER_EDITABLE_STATES = "submitted"

    CASEWORKER_ROLE = "caseworker"
    PROVIDER_ROLE = "provider"

    def allow_update(self, application: Application, roles: List[str]) -> bool:
        if application.application_state in Permissions.LOCKED_STATES:
            # Locked once the application is approved
            return False
        elif not roles:
            # TODO: remove this branch once roles have been implemented
            # on Azure accounts
            return True
        elif application.application_state in Permissions.CASEWORKER_EDITABLE_STATES:
            if Permissions.CASEWORKER_ROLE not in roles:
                return False
        else:
            if Permissions.PROVIDER_ROLE not in roles:
                return False

        return True


def get_permissions():
    return Permissions()
