"""create subscriber table

Revision ID: f9a2f1c1d378
Revises: 7adacb84dfbe
Create Date: 2024-04-04 16:47:49.974867

"""

from typing import Sequence, Union

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "f9a2f1c1d378"
down_revision: Union[str, None] = "7adacb84dfbe"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "subscriber",
        sa.Column("id", UUID(as_uuid=True), primary_key=True),
        sa.Column("subscriber_type", sa.String(50), nullable=False),
        sa.Column("webhook_url", sa.String(50), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("subscriber")
