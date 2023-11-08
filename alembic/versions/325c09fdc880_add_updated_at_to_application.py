"""add updated at to application

Revision ID: 325c09fdc880
Revises: 4728f5eac46d
Create Date: 2023-11-08 11:11:10.954500

"""
from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "325c09fdc880"
down_revision: Union[str, None] = "3a99fcfd6934"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("application", sa.Column("updated_at", sa.DateTime))


def downgrade() -> None:
    op.drop_column("application", "updated_at")
