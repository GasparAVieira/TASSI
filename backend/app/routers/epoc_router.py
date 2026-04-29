from datetime import datetime
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user, require_admin
from app.models.epoc_session import EpocSession
from app.models.user import User
from app.schemas.epoc_session import EpocSessionResponse
from app.services.epoc_service import EpocService

router = APIRouter(prefix="/api/v1/epoc",tags=["EPOC"],)

CLIENT_ID = "com.dansmcb.tassi"
CLIENT_SECRET = "bf33JfPp7emFYrQ8cBogH9LB9eio8cWl2489Ja4p"

epoc_service = EpocService(client_id=CLIENT_ID,client_secret=CLIENT_SECRET,)


@router.post("/connect")
def connect_epoc(
    current_user: User = Depends(get_current_user),
):
    try:
        epoc_service.connect()
        epoc_service.request_access()
        epoc_service.authorize()
        headsets = epoc_service.query_headsets()
        epoc_service.control_device("connect")

        return {
            "message": "Connected to EPOC successfully",
            "headsets": headsets,
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        )


@router.post("/start-session")
def start_epoc_session(
    current_user: User = Depends(get_current_user),
):
    try:
        session = epoc_service.create_session()

        return {
            "message": "EPOC session started",
            "session": session,
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        )


@router.post("/subscribe")
def subscribe_epoc_streams(
    current_user: User = Depends(get_current_user),
):
    try:
        result = epoc_service.subscribe(["com", "met"])

        return {
            "message": "Subscribed to EPOC streams",
            "result": result,
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        )


@router.post(
    "/live",
    response_model=list[EpocSessionResponse],
)
def collect_live_epoc_data(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    collected_sessions = []

    try:
        for packet in epoc_service.receive_data():

            detected_command = None
            attention = None
            engagement = None
            excitement = None
            interest = None
            relaxation = None
            stress = None

            # Mental Commands
            if "com" in packet:
                command_data = packet["com"]

                if isinstance(command_data, list) and len(command_data) >= 1:
                    detected_command = command_data[0]

            # Performance Metrics
            if "met" in packet:
                metrics = packet["met"]

                if isinstance(metrics, list) and len(metrics) >= 6:
                    attention = metrics[0]
                    engagement = metrics[1]
                    excitement = metrics[2]
                    interest = metrics[3]
                    relaxation = metrics[4]
                    stress = metrics[5]

            session_entry = EpocSession(
                participant_id=current_user.id,
                attention=attention,
                engagement=engagement,
                excitement=excitement,
                interest=interest,
                relaxation=relaxation,
                stress=stress,
                detected_command=detected_command,
                recorded_at=datetime.utcnow(),
            )

            db.add(session_entry)
            db.commit()
            db.refresh(session_entry)

            collected_sessions.append(session_entry)

            if len(collected_sessions) >= 10:
                break

        return collected_sessions

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        )


@router.post("/stop")
def stop_epoc_connection(
    current_user: User = Depends(get_current_user),
):
    try:
        epoc_service.close()

        return {
            "message": "EPOC connection closed successfully",
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        )


@router.get(
    "/my-sessions",
    response_model=list[EpocSessionResponse],
)
def list_my_epoc_sessions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return (
        db.query(EpocSession)
        .filter(EpocSession.participant_id == current_user.id)
        .order_by(EpocSession.recorded_at.desc())
        .all()
    )


@router.get(
    "/admin/all-sessions",
    response_model=list[EpocSessionResponse],
)
def list_all_epoc_sessions(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    return (
        db.query(EpocSession)
        .order_by(EpocSession.recorded_at.desc())
        .all()
    )


@router.get(
    "/session/{session_id}",
    response_model=EpocSessionResponse,
)
def get_epoc_session(
    session_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = (
        db.query(EpocSession)
        .filter(
            EpocSession.id == session_id,
            EpocSession.participant_id == current_user.id,
        )
        .first()
    )

    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="EPOC session not found",
        )

    return session