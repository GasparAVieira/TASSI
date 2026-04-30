from typing import Callable, List, Optional
from sqlalchemy.orm import Session

from app.models.user import User

# Uma regra recebe (db, user) e devolve payload ou None
NotificationRule = Callable[[Session, User], Optional[dict]]

RULES: List[NotificationRule] = []


def register_rule(rule: NotificationRule):
    """
    Decorator para registar regras automaticamente.
    """
    RULES.append(rule)
    return rule


def get_rules() -> List[NotificationRule]:
    return RULES