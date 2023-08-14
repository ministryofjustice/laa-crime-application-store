"""split application table

Revision ID: c889c45342e7
Revises: 9152eefe06e0
Create Date: 2023-08-14 10:53:58.073719

"""
from typing import Sequence, Union

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSON, UUID

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "c889c45342e7"
down_revision: Union[str, None] = "9152eefe06e0"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


# I have gonbe the nuclear option of dropping and recreating the table
# as we have no valuable data at this stage and it is significantly easier
# than trying to build a migration script.
def upgrade() -> None:
    op.drop_table("application")

    op.create_table(
        "application",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("current_version", sa.Integer, nullable=False),
        sa.Column("application_state", sa.Text, nullable=False),
        sa.Column("application_risk", sa.Text, nullable=False),
    )

    op.create_table(
        "application_version",
        sa.Column(
            "id",
            UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("application_id", UUID(as_uuid=True), nullable=False),
        sa.Column("version", sa.Integer, nullable=False),
        sa.Column("json_schema_version", sa.Integer, nullable=False),
        sa.Column("application", JSON(), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("application")
    op.drop_table("application_version")

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
