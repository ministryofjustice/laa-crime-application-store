"""Create initial application table

Revision ID: 9152eefe06e0
Revises:
Create Date: 2023-08-09 12:54:19.543072

"""
from typing import Sequence, Union

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSON, UUID

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "9152eefe06e0"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "application",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("claim_id", UUID(as_uuid=True), nullable=False),
        sa.Column("version", sa.Integer, nullable=False),
        sa.Column("json_schema_version", sa.Integer, nullable=False),
        sa.Column("application_state", sa.Text, nullable=False),
        sa.Column("application_risk", sa.Text, nullable=False),
        sa.Column("application", JSON(), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("application")
