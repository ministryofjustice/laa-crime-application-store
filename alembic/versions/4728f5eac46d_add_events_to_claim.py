"""add-events-to-claim

Revision ID: 4728f5eac46d
Revises: c889c45342e7
Create Date: 2023-10-05 13:37:51.093405

"""
from typing import Sequence, Union

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSON

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "4728f5eac46d"
down_revision: Union[str, None] = "c889c45342e7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("application", sa.Column("events", JSON()))


def downgrade() -> None:
    op.drop_column("application", "events")
