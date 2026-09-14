# ==============================================================================
# COCOTUFT PRODUCTION MANAGEMENT SYSTEM - MASTER DATA API ENDPOINTS
# ==============================================================================
# Section Purpose: REST API endpoints delivering database-driven master data
# for dynamic UI form dropdowns (Processes, Machines, Shifts, Orders, Customers, Products).
# ==============================================================================

from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database.session import get_db
from app.models.domain import Process, Machine, Shift, Customer, Order, Product, User
from app.schemas.schemas import ProcessOut, MachineOut, ShiftOut, CustomerOut, OrderOut, ProductOut
from app.core.security import get_current_user

router = APIRouter(tags=["Master Data"])


@router.get("/processes", response_model=List[ProcessOut])
def get_processes(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Section Purpose: Fetches active manufacturing processes (Mixing, Cutting, Shearing, Tufting).
    """
    return db.query(Process).filter(Process.is_active == True).all()


@router.get("/machines", response_model=List[MachineOut])
def get_machines(
    process_id: Optional[int] = Query(None, description="Filter machines by process ID"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Section Purpose: Fetches active machines linked dynamically to processes.
    """
    query = db.query(Machine).filter(Machine.is_active == True)
    if process_id:
        query = query.filter(Machine.process_id == process_id)
    return query.all()


@router.get("/shifts", response_model=List[ShiftOut])
def get_shifts(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Section Purpose: Fetches work shifts.
    """
    return db.query(Shift).filter(Shift.is_active == True).all()


@router.get("/customers", response_model=List[CustomerOut])
def get_customers(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Section Purpose: Fetches active customer list.
    """
    return db.query(Customer).filter(Customer.is_active == True).all()


@router.get("/orders", response_model=List[OrderOut])
def get_orders(
    customer_id: Optional[int] = Query(None, description="Filter orders by customer ID"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Section Purpose: Fetches active Production Sales Orders.
    """
    query = db.query(Order).filter(Order.is_active == True)
    if customer_id:
        query = query.filter(Order.customer_id == customer_id)
    return query.all()


@router.get("/products", response_model=List[ProductOut])
def get_products(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """
    Section Purpose: Fetches finished mat products catalog.
    """
    return db.query(Product).filter(Product.is_active == True).all()
