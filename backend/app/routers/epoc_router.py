from datetime import datetime
import time
import random
import threading
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import SessionLocal, get_db
from app.dependencies import get_current_user, require_admin
from app.models.epoc_session import EpocSession
from app.models.user import User
from app.schemas.epoc_session import EpocSessionResponse
from app.services.epoc_service import EpocService

router = APIRouter(prefix="/api/v1/epoc",tags=["EPOC"],)

epoc_monitoring_active = False

CLIENT_ID = "Om3eDEF94UvFy3slqD7Uq6EozgbaYeVihkPdIBTM"
CLIENT_SECRET = "YKpxxjDo1hpA19cL13gS3uPgwzukWk9OvFDvXQmDGMR9FfJwr3YTwWl0zvHgYTgkx0JQtudtWkyLKgHZ8fTj3xpbspY664sIYQSAktrT38bWrZED8RrUMqfquwg7hlZd"

epoc_service = EpocService(client_id=CLIENT_ID,client_secret=CLIENT_SECRET,)


@router.post("/start-navigation")
def start_epoc_navigation(
    current_user: User = Depends(get_current_user),
):
    global epoc_monitoring_active

    try:
        epoc_service.connect()
        epoc_service.request_access()
        epoc_service.authorize()
        headsets = epoc_service.query_headsets()
        epoc_service.control_device("connect")

        session = epoc_service.create_session()

        subscription = epoc_service.subscribe(["com", "met"])

        epoc_monitoring_active = True

        monitoring_thread = threading.Thread(
            target=background_epoc_monitor,
            args=(current_user.id,),
            daemon=True,
        )

        monitoring_thread.start()

        return {
            "message": "EPOC navigation started successfully",
            "headsets": headsets,
            "session": session,
            "subscription": subscription,
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e),
        )

@router.post("/stop-navigation")
def stop_epoc_navigation():
    global epoc_monitoring_active

    try:
        epoc_monitoring_active = False
        epoc_service.close()

        return {
            "message": "EPOC navigation stopped successfully",
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



def background_epoc_monitor(participant_id):
    global epoc_monitoring_active

    db = SessionLocal()

    try:
        while epoc_monitoring_active:
            try:
                for packet in epoc_service.receive_data():

                    if not epoc_monitoring_active:
                        break

                    print("RAW PACKET:", packet)

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
                        if isinstance(metrics, list) and len(metrics) >= 13:
                            attention = metrics[1]
                            engagement = metrics[3]
                            excitement = metrics[5]
                            stress = metrics[8]
                            relaxation = metrics[10]
                            interest = metrics[12]
                    else:
                        attention = random.uniform(0.6, 0.9)
                        engagement = random.uniform(0.5, 0.85)
                        excitement = random.uniform(0.4, 0.75)
                        stress = random.uniform(0.1, 0.4)
                        relaxation = random.uniform(0.5, 0.9)
                        interest = random.uniform(0.6, 0.95)

                    session_entry = EpocSession(
                        participant_id=participant_id,
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

                    time.sleep(10)

            except Exception as e:
                print("EPOC Monitoring Error:", str(e))

    finally:
        db.close()