"""create que tables

Revision ID: ba2b62aab22b
Revises: f9a2f1c1d378
Create Date: 2024-04-10 11:50:14.138498

"""

from typing import Sequence, Union

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "ba2b62aab22b"
down_revision: Union[str, None] = "f9a2f1c1d378"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "que_jobs",
        sa.Column("id", sa.Integer, nullable=False, primary_key=True),
        sa.Column("priority", sa.Integer, nullable=False, server_default="100"),
        sa.Column(
            "run_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.current_timestamp(),
        ),
        sa.Column("job_class", sa.Text, nullable=False),
        sa.Column("error_count", sa.Integer, server_default="0"),
        sa.Column("last_error_message", sa.Text),
        sa.Column("queue", sa.Text, server_default="default"),
        sa.Column("last_error_backtrace", sa.Text),
        sa.Column("finished_at", sa.DateTime(timezone=True)),
        sa.Column("expired_at", sa.DateTime(timezone=True)),
        sa.Column("args", JSONB, server_default="[]", nullable=False),
        sa.Column("data", JSONB, server_default="{}", nullable=False),
        sa.Column("job_schema_version", sa.Integer, nullable=False, server_default="2"),
        sa.Column("kwargs", JSONB, server_default="{}", nullable=False),
    )

    op.create_table(
        "que_lockers",
        sa.Column("pid", sa.Integer, primary_key=True),
        sa.Column("worker_count", sa.Integer, nullable=False),
        sa.Column("worker_priorities", sa.ARRAY(sa.Integer), nullable=False),
        sa.Column("ruby_pid", sa.Integer, nullable=False),
        sa.Column("ruby_hostname", sa.Text, nullable=False),
        sa.Column("queues", sa.ARRAY(sa.Text), nullable=False),
        sa.Column("listening", sa.Boolean, nullable=False),
        sa.Column("job_schema_version", sa.Integer, server_default="1"),
    )

    op.create_table(
        "que_values",
        sa.Column("key", sa.Text, nullable=False, primary_key=True),
        sa.Column("value", JSONB, server_default="{}", nullable=False),
    )


def downgrade() -> None:
    op.drop_table("que_jobs")
    op.drop_table("que_lockers")
    op.drop_table("que_values")
