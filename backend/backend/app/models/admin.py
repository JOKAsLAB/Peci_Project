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
from sqlalchemy.dialects.postgresql import UUID, ENUM
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
        Integer,
        primary_key=True,
        autoincrement=True
    )

    ID_Professor = Column(
        UUID(as_uuid=True),
        ForeignKey("professor.ID_Professor", ondelete="CASCADE"),
        nullable=False
    )

    ID_Admin = Column(
        UUID(as_uuid=True),
        ForeignKey("admin.ID_Admin", ondelete="SET NULL"),
        nullable=True   # pode não estar resolvido ainda
    )

    # ATENÇÃO: create_type=True (OBRIGATÓRIO PARA ASYNCPG)
    Request_Type = Column(ENUM(RequestType, name="request_type_enum", create_type=True), nullable=False)

    Title        = Column(String(200), nullable=False)
    Description  = Column(Text,        nullable=False)
    
    # ATENÇÃO: create_type=True (OBRIGATÓRIO PARA ASYNCPG)
    Status       = Column(ENUM(RequestStatus, name="request_status_enum", create_type=True), nullable=False, default=RequestStatus.PENDING)
    
    AdminComment = Column(Text,        nullable=True)

    Creation_Date = Column(
        DateTime,
        nullable=False,
        server_default=func.now()
    )

    Resolution_Date = Column(
        DateTime,
        nullable=True
    )

    __table_args__ = (
        # Índices para performance
        Index("idx_request_status", "Status"),
        Index("idx_request_type", "Request_Type"),
        Index("idx_request_professor", "ID_Professor"),
        Index("idx_request_admin", "ID_Admin"),
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
        Integer,
        primary_key=True,
        autoincrement=True
    )

    ID_Admin = Column(
        UUID(as_uuid=True),
        ForeignKey("admin.ID_Admin", ondelete="CASCADE"),
        nullable=False
    )

    Action      = Column(String(100), nullable=False)
    Target_ID   = Column(String(100), nullable=False)
    Target_Type = Column(String(50),  nullable=False)

    Date = Column(
        DateTime,
        nullable=False,
        server_default=func.now()
    )

    __table_args__ = (
        Index("idx_audit_admin", "ID_Admin"),
        Index("idx_audit_date", "Date"),
        Index("idx_audit_target", "Target_ID"),
    )

    # =========================================================
    # Relações
    # =========================================================
    admin = relationship("Admin", back_populates="audit_log_entries")