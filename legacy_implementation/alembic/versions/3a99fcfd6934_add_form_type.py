"""Add Form Type

Revision ID: 3a99fcfd6934
Revises: c889c45342e7
Create Date: 2023-10-04 14:50:19.353271

"""
from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "3a99fcfd6934"
down_revision: Union[str, None] = "4728f5eac46d"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("application", sa.Column("application_type", sa.Text))

    update_rows = sa.text("update application set application_type = 'crm7'")
    connection = op.get_bind()
    connection.execute(update_rows)

    op.alter_column("application", "application_type", nullable=False)


def downgrade() -> None:
    op.drop_column("application", "application_type")
