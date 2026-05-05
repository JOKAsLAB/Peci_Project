import enum

class UserRole(str, enum.Enum):
    STUDENT = "Student"
    PROFESSOR = "Professor"
    ADMIN = "Admin"

class UserStatus(str, enum.Enum):
    ACTIVE = "Active"
    SUSPENDED = "Suspended"
    DEACTIVATED = "Deactivated"

class MaterialStatus(str, enum.Enum):
    PENDING = "Pending"
    INDEXED = "Indexed"
    ERROR = "Error"

class ExerciseType(str, enum.Enum):
    MULTIPLE_CHOICE = "Multiple Choice"
    TRUE_FALSE = "True/False"

class DifficultyLevel(str, enum.Enum):
    EASY = "Easy"
    MEDIUM = "Medium"
    HARD = "Hard"

class ProgressStatus(str, enum.Enum):
    CORRECT = "Correct"
    INCORRECT = "Incorrect"
    PARTIAL = "Partial"

class SyncStatus(str, enum.Enum):
    PENDING = "Pending"
    SYNCED = "Synced"
    FAILED = "Failed"

class RequestStatus(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"

class RequestType(str, enum.Enum):
    ACCESS = "access"
    PLATFORM = "platform"
    OPERATIONS = "operations"
    OTHER = "other"

class QuizSessionStatus(str, enum.Enum):
    WAITING = "waiting"
    ACTIVE = "active"
    FINISHED = "finished"