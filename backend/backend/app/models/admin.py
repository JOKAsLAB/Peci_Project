# =============================================================
# PECI PROJECT — Models: Admin & Governance
#
# Espelha as tabelas SQL:
#   Request, Admin_Audit_Log
#
# Responsabilidades:
#   - Gestão de pedidos de professores
#   - Auditoria de ações administrativas
# =============================================================

from sqlalchemy import (
    Column, String, Text, DateTime,
    ForeignKey, Index, Integer
)
from sqlalchemy.dialects.postgresql import UUID
from app.models.utils import EnumColumn
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.database import Base
from app.models.enums import RequestStatus, RequestType


# =============================================================
# Request
# Professores enviam pedidos → Admin aprova/rejeita
# =============================================================
class Request(Base):
    __tablename__ = "request"

    ID_Request = Column(
        "id_request",
        Integer,
        primary_key=True,
        autoincrement=True
    )

    ID_Professor = Column(
        "id_professor",
        UUID(as_uuid=True),
        ForeignKey("professor.id_professor", ondelete="CASCADE"),
        nullable=False
    )

    ID_Admin = Column(
        "id_admin",
        UUID(as_uuid=True),
        ForeignKey("admin.id_admin", ondelete="SET NULL"),
        nullable=True   # pode não estar resolvido ainda
    )

    # ATENÇÃO: create_type=True (OBRIGATÓRIO PARA ASYNCPG)
    Request_Type = Column(
        "request_type", 
        EnumColumn(RequestType, name="request_type_enum", create_type=True), 
        nullable=False
    )

    Title        = Column("title", String(200), nullable=False)
    Description  = Column("description", Text,        nullable=False)

    # ATENÇÃO: create_type=True (OBRIGATÓRIO PARA ASYNCPG)
    Status = Column(
        "status", 
        EnumColumn(RequestStatus, name="request_status_enum", create_type=True), 
        nullable=False, 
        default=RequestStatus.PENDING
    )
    
    AdminComment = Column("admin_comment", Text,        nullable=True)

    Creation_Date = Column(
        "creation_date",
        DateTime,
        nullable=False,
        server_default=func.now()
    )

    Resolution_Date = Column(
        "resolution_date",
        DateTime,
        nullable=True
    )

    __table_args__ = (
        # Índices para performance
        Index("idx_request_status", "status"),
        Index("idx_request_type", "request_type"),
        Index("idx_request_professor", "id_professor"),
        Index("idx_request_admin", "id_admin"),
    )

    # =========================================================
    # Relações
    # =========================================================
    professor = relationship("Professor", back_populates="requests")
    admin     = relationship("Admin",     back_populates="requests")


# =============================================================
# Admin_Audit_Log
# Registo de ações críticas feitas por administradores
# =============================================================
class Admin_Audit_Log(Base):
    __tablename__ = "admin_audit_log"

    ID_Log = Column(
        "id_log",
        Integer,
        primary_key=True,
        autoincrement=True
    )

    ID_Admin = Column(
        "id_admin",
        UUID(as_uuid=True),
        ForeignKey("admin.id_admin", ondelete="CASCADE"),
        nullable=False
    )

    Action      = Column("action", String(100), nullable=False)
    Target_ID   = Column("target_id", String(100), nullable=False)
    Target_Type = Column("target_type", String(50),  nullable=False)

    Date = Column(
        "date",
        DateTime,
        nullable=False,
        server_default=func.now()
    )

    __table_args__ = (
        Index("idx_audit_admin", "id_admin"),
        Index("idx_audit_date", "date"),
        Index("idx_audit_target", "target_id"),
    )

    # =========================================================
    # Relações
    # =========================================================
    admin = relationship("Admin", back_populates="audit_log_entries")