import os
import sys
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import parse_xml, OxmlElement
from docx.oxml.ns import nsdecls, qn

DOCX_OUTPUT_PATH = r"D:\dbms project\sports_club_dbms\docs\WU2024CSE042_LeadDeveloper_DBMS_PBL_Report.docx"
DOCX_COPY_PATH = r"D:\dbms project\sports_club_dbms\docs\DBMS_PBL_Report.docx"
DOCS_DIR = r"D:\dbms project\sports_club_dbms\docs"

doc = docx.Document()

# ---------------------------------------------------------
# Page Setup: A4, 1-inch margins
# ---------------------------------------------------------
for section in doc.sections:
    section.page_width = Inches(8.27)
    section.page_height = Inches(11.69)
    section.top_margin = Inches(1.0)
    section.bottom_margin = Inches(1.0)
    section.left_margin = Inches(1.0)
    section.right_margin = Inches(1.0)

# Configure default style
style_normal = doc.styles['Normal']
font = style_normal.font
font.name = 'Times New Roman'
font.size = Pt(12)
font.color.rgb = RGBColor(0x11, 0x18, 0x27)

def set_cell_background(cell, fill_hex):
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    cell._tc.get_or_add_tcPr().append(shd)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
    tcPr.append(tcMar)

def set_table_borders(table, color="CCCCCC"):
    tblPr = table._tbl.tblPr
    borders = parse_xml(f'''
        <w:tblBorders {nsdecls("w")}>
            <w:top w:val="single" w:sz="6" w:space="0" w:color="{color}"/>
            <w:bottom w:val="single" w:sz="8" w:space="0" w:color="{color}"/>
            <w:insideH w:val="single" w:sz="4" w:space="0" w:color="{color}"/>
            <w:insideV w:val="none"/>
            <w:left w:val="none"/>
            <w:right w:val="none"/>
        </w:tblBorders>
    ''')
    tblPr.append(borders)

def add_chapter_title(text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(16)
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.line_spacing = 1.5
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text.upper())
    run.font.name = 'Times New Roman'
    run.font.size = Pt(16)
    run.font.bold = True
    run.font.color.rgb = RGBColor(0x0f, 0x17, 0x2a)
    return p

def add_section_title(text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(12)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.line_spacing = 1.5
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text)
    run.font.name = 'Times New Roman'
    run.font.size = Pt(14)
    run.font.bold = True
    run.font.color.rgb = RGBColor(0x1e, 0x29, 0x3b)
    return p

def add_subsection_title(text):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(8)
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.line_spacing = 1.5
    p.paragraph_format.keep_with_next = True
    run = p.add_run(text)
    run.font.name = 'Times New Roman'
    run.font.size = Pt(13)
    run.font.bold = True
    run.font.color.rgb = RGBColor(0x33, 0x41, 0x55)
    return p

def add_body(text, bold_prefix=None):
    p = doc.add_paragraph()
    p.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.paragraph_format.line_spacing = 1.5
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.space_before = Pt(0)
    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        r_pre.font.name = 'Times New Roman'
        r_pre.font.size = Pt(12)
        r_pre.font.bold = True
    run = p.add_run(text)
    run.font.name = 'Times New Roman'
    run.font.size = Pt(12)
    return p

def add_bullet(text, bold_prefix=None):
    p = doc.add_paragraph(style='List Bullet')
    p.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.paragraph_format.line_spacing = 1.5
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.space_before = Pt(0)
    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        r_pre.font.name = 'Times New Roman'
        r_pre.font.size = Pt(12)
        r_pre.font.bold = True
    run = p.add_run(text)
    run.font.name = 'Times New Roman'
    run.font.size = Pt(12)
    return p

def add_code(code_str):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.line_spacing = 1.15
    p.paragraph_format.left_indent = Inches(0.2)
    for line in code_str.strip().split('\n'):
        run = p.add_run(line + '\n')
        run.font.name = 'Courier New'
        run.font.size = Pt(10)
        run.font.color.rgb = RGBColor(0x1e, 0x29, 0x3b)

def add_table(title, headers, rows, col_widths=None):
    # Table Title placed ABOVE table
    tp = doc.add_paragraph()
    tp.paragraph_format.space_before = Pt(10)
    tp.paragraph_format.space_after = Pt(4)
    tp.paragraph_format.keep_with_next = True
    r = tp.add_run(title)
    r.font.name = 'Times New Roman'
    r.font.size = Pt(11)
    r.font.bold = True
    r.font.color.rgb = RGBColor(0x0f, 0x17, 0x2a)

    tbl = doc.add_table(rows=len(rows)+1, cols=len(headers))
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_table_borders(tbl)

    # Headers
    hdr_cells = tbl.rows[0].cells
    for i, h in enumerate(headers):
        hdr_cells[i].text = h
        set_cell_background(hdr_cells[i], "EBF3FA")
        set_cell_margins(hdr_cells[i], top=120, bottom=120, left=140, right=140)
        p = hdr_cells[i].paragraphs[0]
        p.paragraph_format.line_spacing = 1.15
        p.paragraph_format.space_after = Pt(0)
        for run in p.runs:
            run.font.name = 'Times New Roman'
            run.font.size = Pt(10.5)
            run.font.bold = True
            run.font.color.rgb = RGBColor(0x0f, 0x29, 0x4a)

    # Rows
    for r_idx, r_data in enumerate(rows):
        row_cells = tbl.rows[r_idx+1].cells
        bg_color = "F9FBFC" if r_idx % 2 == 1 else "FFFFFF"
        for c_idx, val in enumerate(r_data):
            row_cells[c_idx].text = str(val)
            set_cell_background(row_cells[c_idx], bg_color)
            set_cell_margins(row_cells[c_idx], top=90, bottom=90, left=140, right=140)
            p = row_cells[c_idx].paragraphs[0]
            p.paragraph_format.line_spacing = 1.15
            p.paragraph_format.space_after = Pt(0)
            for run in p.runs:
                run.font.name = 'Times New Roman'
                run.font.size = Pt(10)
                run.font.color.rgb = RGBColor(0x33, 0x41, 0x55)

    if col_widths:
        for row in tbl.rows:
            for i, w in enumerate(col_widths):
                row.cells[i].width = Inches(w)

    doc.add_paragraph().paragraph_format.space_after = Pt(4)

def add_figure(img_filename, caption, width_in=6.0):
    img_path = os.path.join(DOCS_DIR, img_filename)
    if os.path.exists(img_path):
        p_img = doc.add_paragraph()
        p_img.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p_img.paragraph_format.space_before = Pt(8)
        p_img.paragraph_format.space_after = Pt(4)
        run_img = p_img.add_run()
        run_img.add_picture(img_path, width=Inches(width_in))
    
    # Caption placed BELOW figure
    p_cap = doc.add_paragraph()
    p_cap.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p_cap.paragraph_format.space_before = Pt(2)
    p_cap.paragraph_format.space_after = Pt(10)
    run_cap = p_cap.add_run(caption)
    run_cap.font.name = 'Times New Roman'
    run_cap.font.size = Pt(11)
    run_cap.font.bold = True
    run_cap.font.color.rgb = RGBColor(0x1e, 0x29, 0x3b)


print("Building Document Sections...")

# =========================================================================
# COVER / TITLE PAGE (Page 3 format)
# =========================================================================
p_inst = doc.add_paragraph()
p_inst.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER
p_inst.paragraph_format.space_before = Pt(10)
p_inst.paragraph_format.space_after = Pt(2)
r = p_inst.add_run("SCHOOL OF TECHNOLOGY\nWOXSEN UNIVERSITY")
r.font.name = 'Times New Roman'
r.font.size = Pt(16)
r.font.bold = True
r.font.color.rgb = RGBColor(0x0f, 0x17, 0x2a)

p_sub = doc.add_paragraph()
p_sub.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER
p_sub.paragraph_format.space_before = Pt(18)
p_sub.paragraph_format.space_after = Pt(4)
r2 = p_sub.add_run("DATABASE MANAGEMENT SYSTEMS\nPROJECT-BASED LEARNING (PBL) REPORT\n")
r2.font.name = 'Times New Roman'
r2.font.size = Pt(14)
r2.font.bold = True

r2_sub = p_sub.add_run("Small Database Application Development using Python & MySQL")
r2_sub.font.name = 'Times New Roman'
r2_sub.font.size = Pt(12)
r2_sub.font.italic = True

p_box = doc.add_paragraph()
p_box.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER
p_box.paragraph_format.space_before = Pt(24)
p_box.paragraph_format.space_after = Pt(24)
r_box = p_box.add_run("PROJECT TITLE\n\nDESIGN AND IMPLEMENTATION OF A DATABASE MANAGEMENT SYSTEM FOR SPORTS CLUB MEMBERSHIP AND TOURNAMENT MANAGEMENT")
r_box.font.name = 'Times New Roman'
r_box.font.size = Pt(14)
r_box.font.bold = True
r_box.font.color.rgb = RGBColor(0x0a, 0x25, 0x40)

# Project metadata table
meta_headers = ["Attribute", "Details"]
meta_rows = [
    ["Program", "B.Tech. Computer Science & Engineering"],
    ["Course", "Database Management Systems (DBMS)"],
    ["Section", "CSE - Core"],
    ["Faculty Guide", "Course Faculty, School of Technology"],
    ["Date of Submission", "October 12, 2026"],
    ["Academic Year", "2026 – 2027"]
]
add_table("Project Academic Record", meta_headers, meta_rows, col_widths=[2.2, 4.0])

# Submitted by table
sub_headers = ["Roll Number", "Student Name", "Mobile", "Email ID"]
sub_rows = [
    ["WU/2024/CSE/042", "Lead Developer", "+91 98111 00001", "student@woxsen.edu.in"]
]
add_table("Submitted by", sub_headers, sub_rows, col_widths=[1.6, 1.8, 1.4, 1.4])

doc.add_page_break()

# =========================================================================
# ACKNOWLEDGEMENT (Page 4 format)
# =========================================================================
add_chapter_title("ACKNOWLEDGEMENT")

add_body("I express my sincere gratitude to Woxsen University, School of Technology, for providing me with the opportunity to undertake this Project-Based Learning (PBL) activity as part of the Database Management Systems (DBMS) course.")

add_body("I thank my course faculty, Name of the Faculty, for the guidance, suggestions, and support throughout the design and development of this project. The guidance helped me understand and synthesize the practical application of database concepts such as ER modelling, relational schema design, normalization up to 3NF/BCNF, declarative SQL constraints, triggers, transactional stored procedures, indexing for query optimization, and full-stack database application development.")

add_body("This PBL activity has significantly strengthened my understanding of DBMS concepts and provided valuable real-world experience in engineering an ACID-compliant, reliable software solution.")

doc.add_page_break()

# =========================================================================
# UNDERTAKING (Page 5 format)
# =========================================================================
add_chapter_title("UNDERTAKING")

add_body("I hereby declare that the project entitled “Design and Implementation of a Database Management System for Sports Club Membership and Tournament Management”, submitted as part of the Project-Based Learning activity for the Database Management Systems (DBMS) course, is my individual work carried out under the guidance of the course faculty.")

add_body("I undertake that the project report, database design, SQL scripts, application source code, results, and supporting materials submitted by me have been prepared for academic purposes. Wherever information, ideas, tools, datasets, or other resources have been referred to, appropriate acknowledgement in IEEE format has been provided.")

add_body("I further undertake that I am responsible for the correctness and authenticity of the work submitted and that I have followed the academic and project guidelines prescribed by the University.")

p_sig = doc.add_paragraph()
p_sig.paragraph_format.space_before = Pt(36)
p_sig.paragraph_format.line_spacing = 1.5
r_sig = p_sig.add_run(
    "Date : October 12, 2026\t\t\t\tSignature: __________________________\n"
    "Place: Hyderabad, India\t\t\t\tName: Lead Developer\n"
    "\t\t\t\t\t\tRoll Number: WU/2024/CSE/042\n"
    "\t\t\t\t\t\tProgram: B.Tech. CSE"
)
r_sig.font.name = 'Times New Roman'
r_sig.font.size = Pt(12)

doc.add_page_break()

# =========================================================================
# TABLE OF CONTENTS (Page 6 format)
# =========================================================================
add_chapter_title("TABLE OF CONTENTS")

toc_headers = ["Contents", "Page No."]
toc_rows = [
    ["Abstract", "1"],
    ["LIST OF TABLES", "2"],
    ["LIST OF FIGURES", "3"],
    ["LIST OF ACRONYMS", "4"],
    ["1. PROBLEM STATEMENT, SOLUTION STRATEGY AND ER DIAGRAM", "5"],
    ["   1.1 Problem Statement", "5"],
    ["   1.2 Objectives", "5"],
    ["   1.3 Scope and Assumptions", "6"],
    ["   1.4 Proposed Solution Strategy", "7"],
    ["   1.5 Functional Requirements", "8"],
    ["   1.6 Entity-Relationship Diagram (ERD)", "9"],
    ["   1.7 Entity and Relationship Summary", "11"],
    ["2. LOGICAL DATABASE DESIGN", "13"],
    ["   2.1 Relational Schema", "13"],
    ["   2.2 Keys and Integrity Constraints", "14"],
    ["   2.3 Functional Dependencies", "16"],
    ["   2.4 Normalization up to Third Normal Form (3NF)", "18"],
    ["   2.5 Data Dictionary", "20"],
    ["   2.6 Implementation of Logical Design: DDL and Sample Data", "24"],
    ["3. APPLICATION DEVELOPMENT USING LOGICAL DATABASE DESIGN", "27"],
    ["   3.1 Application Overview", "27"],
    ["   3.2 Development Environment and Database Connectivity", "27"],
    ["   3.3 Application Modules and Database Mapping", "28"],
    ["   3.4 CRUD Operations", "29"],
    ["   3.5 Business Rules, Validation and Error Handling", "30"],
    ["   3.6 Reports and Database Operations", "32"],
    ["   3.7 Application Screens", "33"],
    ["   3.8 Testing and Results", "35"],
    ["4. CONCLUSION", "38"],
    ["   4.1 Limitations and Future Enhancements", "38"],
    ["5. REFERENCES", "39"],
    ["6. APPENDICES", "40"]
]
add_table("Table of Contents", toc_headers, toc_rows, col_widths=[5.0, 1.2])

doc.add_page_break()

# =========================================================================
# LIST OF TABLES, FIGURES, ACRONYMS (Pages 7, 8, 9)
# =========================================================================
add_chapter_title("LIST OF TABLES")
lot_headers = ["Table No.", "Table Title", "Page No."]
lot_rows = [
    ["Table 1", "Scope and Assumptions", "6"],
    ["Table 2", "Proposed Solution Strategy", "7"],
    ["Table 3", "Functional Requirements", "8"],
    ["Table 4", "Entity and Relationship Summary", "11"],
    ["Table 5", "Relational Schema", "13"],
    ["Table 6", "Keys and Integrity Constraints", "14"],
    ["Table 7", "Normalization Status up to 3NF", "18"],
    ["Table 8", "Data Dictionary", "20"],
    ["Table 9", "Database Implementation Environment", "24"],
    ["Table 10", "Application Development Environment", "27"],
    ["Table 11", "Application Module-to-Database Mapping", "28"],
    ["Table 12", "CRUD Operations", "29"],
    ["Table 13", "Business Rules, Validation and Error Handling", "30"],
    ["Table 14", "Reports and Database Operations", "32"],
    ["Table 15", "Test Cases", "35"]
]
add_table("List of Tables", lot_headers, lot_rows, col_widths=[1.4, 4.0, 0.8])

doc.add_paragraph().paragraph_format.space_after = Pt(12)
add_chapter_title("LIST OF FIGURES")
lof_headers = ["Figure No.", "Figure Title", "Page No."]
lof_rows = [
    ["Figure 1", "Entity-Relationship Diagram of the Proposed System", "9"],
    ["Figure 2", "Dashboard and Operational Metrics Screen", "33"],
    ["Figure 3", "Member Registration and Profile Management Screen", "33"],
    ["Figure 4", "Match Fixture Scheduling and Live Conflict Checker Screen", "34"],
    ["Figure 5", "Match Results Entry and Standings Reporting Screen", "34"]
]
add_table("List of Figures", lof_headers, lof_rows, col_widths=[1.4, 4.0, 0.8])

doc.add_page_break()

add_chapter_title("LIST OF ACRONYMS")
acro_headers = ["Acronym", "Expansion"]
acro_rows = [
    ["1NF", "First Normal Form"],
    ["2NF", "Second Normal Form"],
    ["3NF", "Third Normal Form"],
    ["ACID", "Atomicity, Consistency, Isolation, Durability"],
    ["API", "Application Programming Interface"],
    ["BCNF", "Boyce-Codd Normal Form"],
    ["CRUD", "Create, Read, Update, Delete"],
    ["CSS", "Cascading Style Sheets"],
    ["CSV", "Comma-Separated Values"],
    ["DBMS", "Database Management System"],
    ["DDL", "Data Definition Language"],
    ["DML", "Data Manipulation Language"],
    ["ER", "Entity-Relationship"],
    ["ERD", "Entity-Relationship Diagram"],
    ["FD", "Functional Dependency"],
    ["FK", "Foreign Key"],
    ["GF", "Goals For / Points For"],
    ["GA", "Goals Against / Points Against"],
    ["GD", "Goal Difference"],
    ["HTML", "HyperText Markup Language"],
    ["HTTP", "Hypertext Transfer Protocol"],
    ["IDE", "Integrated Development Environment"],
    ["IEEE", "Institute of Electrical and Electronics Engineers"],
    ["PBL", "Project-Based Learning"],
    ["PK", "Primary Key"],
    ["RDBMS", "Relational Database Management System"],
    ["SQL", "Structured Query Language"],
    ["UI", "User Interface"],
    ["UK", "Unique Key"],
    ["UPI", "Unified Payments Interface"],
    ["URL", "Uniform Resource Locator"]
]
add_table("List of Acronyms", acro_headers, acro_rows, col_widths=[1.8, 4.4])

doc.add_page_break()

# =========================================================================
# ABSTRACT (Page 10 format)
# =========================================================================
add_chapter_title("ABSTRACT")

abstract_text = (
    "Modern athletic clubs and sports complexes face severe administrative challenges due to fragmented data management, "
    "resulting in scheduling collisions on shared facilities, unenforced squad quotas, untracked sports equipment loans, "
    "and lost revenue from expired memberships. To address these operational issues, this project presents the design "
    "and implementation of a comprehensive, relational database management system for sports club membership and "
    "tournament management. The backend is engineered in MySQL 8.x and consists of fourteen normalized relational tables "
    "structured in Third Normal Form (3NF) and Boyce-Codd Normal Form (BCNF), eliminating data redundancy and update anomalies. "
    "Complex business rules—such as cross-table facility schedule collision detection, simultaneous team commitment prevention, "
    "active subscription enforcement, roster capacity ceilings, winner-score consistency, and equipment borrowing quotas—are "
    "implemented at the database tier using declarative triggers and transactional stored procedures with ACID rollback protection. "
    "A responsive, user-friendly full-stack application developed with Python 3.10 and Flask connects to the database via connection "
    "pooling, providing parameterized CRUD operations, interactive slot conflict diagnostics, result processing, and eight live "
    "analytical reports with instant CSV export capabilities. Experimental validation through a 26-test SQL constraint harness "
    "and a 21-test pytest integration suite demonstrates a 100% pass rate, verifying rigorous data integrity, zero scheduling "
    "conflicts, and reliable athletic facility orchestration."
)
add_body(abstract_text)

p_kw = doc.add_paragraph()
p_kw.paragraph_format.space_before = Pt(12)
p_kw.paragraph_format.line_spacing = 1.5
r_kw_title = p_kw.add_run("Keywords: ")
r_kw_title.font.name = 'Times New Roman'
r_kw_title.font.size = Pt(12)
r_kw_title.font.bold = True
r_kw_val = p_kw.add_run("Relational Database, ER Diagram, Normalization, SQL, Python Flask, Sports Club Management")
r_kw_val.font.name = 'Times New Roman'
r_kw_val.font.size = Pt(12)
r_kw_val.font.italic = True

doc.add_page_break()

# =========================================================================
# CHAPTER 1 (Pages 11-12)
# =========================================================================
add_chapter_title("CHAPTER 1")
add_chapter_title("PROBLEM STATEMENT, SOLUTION STRATEGY AND ER DIAGRAM")

add_section_title("1.1 Problem Statement")
add_body(
    "Contemporary sports complexes, athletic academies, and multi-sport community clubs manage a wide array of interconnected "
    "activities: patron subscriptions, coaching staff assignments, squad team rosters, practice sessions, competitive tournaments, "
    "match fixtures, fee collections, and equipment inventory custody. In traditional administrative setups, these operational "
    "workflows are maintained through isolated spreadsheets, manual paper logbooks, or disconnected software tools."
)
add_body(
    "This fragmented paradigm causes significant operational failures. Primary issues include double-booking of scarce club venues "
    "(e.g., cricket grounds, hardwood courts, football turfs) across practice sessions and competitive fixtures; squad players being "
    "scheduled for multiple concurrent events; unenforced safety and facility capacity limits; unreturned and overdue equipment checkout "
    "tracking; and lost revenue due to lapses in identifying expired member subscriptions. To solve these vulnerabilities, there is an "
    "urgent need for an integrated, ACID-compliant relational database management system that strictly enforces data integrity constraints, "
    "prevents scheduling collisions at the database level, automates subscription lifecycles, and provides transparent administrative "
    "oversight through structured web interfaces."
)

add_section_title("1.2 Objectives")
add_body("The primary objectives of this project are:")
add_bullet(" a normalized relational database schema in 3NF/BCNF consisting of fourteen interconnected tables that comprehensively captures club operations, memberships, sports, teams, fixtures, and inventory.", bold_prefix="Design")
add_bullet(" declarative integrity constraints, foreign keys with appropriate cascade/restrict actions, and database triggers that enforce complex business rules (e.g., cross-table venue schedule collision prevention, team conflict checks, roster limits, score validation).", bold_prefix="Implement")
add_bullet(" transactional stored procedures with ACID compliance (START TRANSACTION, COMMIT, ROLLBACK) for atomic multi-table operations such as member registration with payment, renewal, match result finalization, and equipment checkout.", bold_prefix="Develop")
add_bullet(" an interactive, modular web application using Python, Flask, and Bootstrap 5 that connects to the database via connection pooling and executes parameterized CRUD workflows.", bold_prefix="Build")
add_bullet(" eight real-time operational and analytical views (including dynamic tournament league standings with 3-1-0 points computation and facility utilization reports) accompanied by one-click CSV export.", bold_prefix="Generate")
add_bullet(" database robustness and business rule enforcement using an automated SQL constraint test suite and a Python integration test harness.", bold_prefix="Validate")

add_section_title("1.3 Scope and Assumptions")
t1_headers = ["Item", "Description"]
t1_rows = [
    ["In Scope", "• Management of 5 subscription tiers and member profiles.\n• Financial fee collection tracking (Paid vs. Pending across Cash, UPI, Card, Bank).\n• Team formation across 6 sports with coach assignments and roster caps.\n• Facility reservation and training drill scheduling with collision prevention.\n• Tournament organization, match fixture scheduling, and player participation.\n• Match score recording with automated winner determination and standings generation.\n• Sports equipment checkout, due date tracking, overdue alerts, and return processing.\n• Live SQL views and CSV report downloads."],
    ["Out of Scope / Exclusions", "• External banking payment gateway processing (mocked via transaction recording).\n• Biometric physical access gate turnstile hardware integration.\n• Member-facing public mobile app (system is designed for club operations and administrators)."],
    ["Assumptions", "• All dates and session times are recorded within a unified club timezone.\n• A member must hold an active, non-expired subscription to be enrolled in squads, fixtures, or borrow equipment.\n• Tournament fixtures are contested between two distinct club teams.\n• Standard sporting point convention: 3 points for a win, 1 point for a draw, 0 points for a loss."]
]
add_table("Table 1. Scope and Assumptions", t1_headers, t1_rows, col_widths=[2.0, 4.2])

add_section_title("1.4 Proposed Solution Strategy")
add_body(
    "The proposed solution implements a dual-tier architecture: an enterprise-grade database engine (MySQL 8.x) coupled with an "
    "administrative web application (Python Flask). Rather than relying solely on client-side application logic—which can be bypassed "
    "by direct database connections or concurrency races—the architecture embeds business rules directly into the database engine "
    "via constraints, triggers, and stored procedures."
)
t2_headers = ["Solution Element", "Project-Specific Description"]
t2_rows = [
    ["Primary Users / Roles", "Club Administrators, Sports Directors, Equipment Managers, Operations Staff."],
    ["Major Application Modules", "Dashboard, Membership, Team Formation, Training Scheduling, Facility Booking, Match Fixtures, Result Entry, Fee Collection, Equipment Management, Reports."],
    ["Proposed Workflow", "Member registers with initial plan fee -> Assigned to athletic squads -> Coach schedules training drills on available venues -> Tournament fixtures are generated -> Match results submitted and automatically update standings -> Equipment checked out under member quotas -> Automated maintenance flags expired memberships and overdue gear."],
    ["Important Business Rules", "Cross-table venue overlap prevention; team concurrent engagement block; active membership requirement; roster capacity caps; score and winner consistency; maximum 3 unreturned items per patron; maintenance venue protection; sport specialization matching."],
    ["Expected Reports / Outputs", "Active Memberships, Expiring Subscriptions (30-day window), Fixture Schedule Calendar, Tournament Standings (played, W/D/L, GF, GA, GD, points, rank), Facility Utilization, Player Performance, Fee Dues & Arrears, Equipment Inventory Status."]
]
add_table("Table 2. Proposed Solution Strategy", t2_headers, t2_rows, col_widths=[2.2, 4.0])

add_section_title("1.5 Functional Requirements")
t3_headers = ["Req. ID", "Functional Requirement", "Remarks / Priority"]
t3_rows = [
    ["FR-01", "Membership Registration & Payment: System shall register patrons, calculate subscription validity from plan duration, and record initial fee transaction atomically.", "High / Mandatory"],
    ["FR-02", "Subscription Renewal: System shall extend validity from either current expiry or today's date and log renewal receipts.", "High / Mandatory"],
    ["FR-03", "Team Formation & Rostering: System shall form teams affiliated with sports and coaches, allowing roster additions up to the sport's maximum size.", "High / Mandatory"],
    ["FR-04", "Venue Conflict Prevention: System shall prohibit booking any venue if an overlapping training session or fixture is already scheduled.", "High / Critical"],
    ["FR-05", "Team Schedule Conflict Prevention: System shall prohibit scheduling a squad if it already has a training drill or match at overlapping times.", "High / Critical"],
    ["FR-06", "Active Membership Enforcement: System shall block inactive or expired members from joining squads, match lineups, or checking out gear.", "High / Critical"],
    ["FR-07", "Match Fixture Scheduling: System shall schedule tournament fixtures ensuring participating teams and the venue match the tournament's sport.", "High / Mandatory"],
    ["FR-08", "Score Recording & Auto-Completion: System shall record non-negative scores, validate winner integrity, and mark fixtures completed atomically.", "High / Critical"],
    ["FR-09", "Equipment Loan Quota Control: System shall restrict members to at most 3 active gear loans and block checkouts if any loan is overdue.", "High / Mandatory"],
    ["FR-10", "Analytical Reporting & CSV Export: System shall dynamically execute all database views and provide CSV downloads.", "Medium / Desirable"]
]
add_table("Table 3. Functional Requirements", t3_headers, t3_rows, col_widths=[1.1, 3.9, 1.2])

add_section_title("1.6 Entity-Relationship Diagram (ERD)")
add_body(
    "The conceptual data model of the Sports Club DBMS was designed using Crow's Foot notation to represent the fourteen core entities, "
    "their primary keys, foreign keys, and cardinalities. As illustrated in Figure 1, the design enforces full relational connectivity "
    "across patrons, athletic teams, venues, tournaments, and inventory assets."
)
add_figure("fig1_er_diagram.png", "Figure 1. Entity-Relationship Diagram of the Proposed System", width_in=6.2)

add_section_title("1.7 Entity and Relationship Summary")
t4_headers = ["Entity / Relationship", "Major Attributes / Cardinality", "Purpose / Rule"]
t4_rows = [
    ["membership_plan", "plan_id (PK), plan_name, duration_months, fee, benefits", "Stores club subscription tiers; parent to members and fee charges."],
    ["member", "member_id (PK), name, phone, email, plan_id (FK), membership_start, membership_end, status", "Core club patron record; enforces date ordering and active subscription."],
    ["payment", "payment_id (PK), member_id (FK), plan_id (FK), amount, payment_date, mode, status", "Accounting ledger; financial history protected via ON DELETE RESTRICT."],
    ["sport", "sport_id (PK), sport_name, category, max_team_size", "Defines sporting disciplines and roster capacity limits."],
    ["coach", "coach_id (PK), name, phone, specialization, sport_id (FK)", "Certified instructors affiliated with a sporting specialization."],
    ["team", "team_id (PK), team_name, sport_id (FK), coach_id (FK), formed_on", "Athletic club squads; verified to ensure coach sport matches team sport."],
    ["team_member", "team_member_id (PK), team_id (FK), member_id (FK), role, joined_on", "M:N associative entity; enforces squad cap and active member checks."],
    ["facility", "facility_id (PK), facility_name, type, capacity, status", "Physical venue assets; protects against booking venues under maintenance."],
    ["training_session", "session_id (PK), team_id (FK), coach_id (FK), facility_id (FK), session_date, start_time, end_time", "Scheduled team practice; protected by cross-table overlap triggers."],
    ["tournament", "tournament_id (PK), tournament_name, sport_id (FK), start_date, end_date", "Master competitive events organized by the club."],
    ["fixture", "fixture_id (PK), tournament_id (FK), facility_id (FK), team1_id (FK), team2_id (FK), dates/times, status", "Scheduled match contest between two distinct teams."],
    ["participant", "participant_id (PK), fixture_id (FK), team_id (FK), member_id (FK), role", "Match lineup rosters; checks member active status and facility capacity."],
    ["result", "result_id (PK), fixture_id (FK), team1_score, team2_score, winner_team_id (FK), remarks", "1:1 post-match outcome; enforces valid scores and winner integrity."],
    ["equipment_issue", "issue_id (PK), member_id (FK), equipment_name, quantity, issue_date, due_date, return_date, status", "Equipment checkout tracking; enforces 3-item limit and overdue blocks."],
    ["MEMBERSHIP_PLAN - MEMBER", "1 : N (One-to-Many)", "One plan can be held by multiple members; a member holds one plan at a time."],
    ["SPORT - TEAM", "1 : N (One-to-Many)", "One sport governs multiple teams; a team belongs to exactly one sport."],
    ["TEAM - MEMBER", "M : N (Many-to-Many)", "Resolved via team_member associative relation."],
    ["FIXTURE - RESULT", "1 : 1 (One-to-One)", "Each scheduled fixture has at most one final result record (UNIQUE(fixture_id))."]
]
add_table("Table 4. Entity and Relationship Summary", t4_headers, t4_rows, col_widths=[1.8, 2.2, 2.2])

doc.add_page_break()

# =========================================================================
# CHAPTER 2 (Pages 13-15)
# =========================================================================
add_chapter_title("CHAPTER 2")
add_chapter_title("LOGICAL DATABASE DESIGN")

add_section_title("2.1 Relational Schema")
add_body(
    "The conceptual ER model was mapped to fourteen logical relational tables. Every relation possesses an artificial surrogate primary "
    "key for referential performance, supplemented by natural candidate keys and explicit foreign keys."
)
t5_headers = ["S.No.", "Table Name", "Purpose"]
t5_rows = [
    ["1", "membership_plan", "Catalogs subscription packages, durations in months, fees, and entitlements."],
    ["2", "member", "Stores patron profiles, contact channels, validity dates, and account status."],
    ["3", "payment", "Financial transaction audit ledger for registrations and renewals."],
    ["4", "sport", "Catalogs sporting disciplines, team categories, and maximum roster sizes."],
    ["5", "coach", "Stores coaching staff qualifications, phone numbers, and sport specializations."],
    ["6", "team", "Catalogs club athletic squads affiliated with a sport and assigned head coach."],
    ["7", "team_member", "M:N roster table associating members with teams and athletic roles."],
    ["8", "facility", "Stores grounds, courts, turfs, venue capacities, and operational maintenance status."],
    ["9", "training_session", "Schedules team practice drills reserving a facility and coach."],
    ["10", "tournament", "Tracks multi-day competitive sporting championships and disciplines."],
    ["11", "fixture", "Manages head-to-head match encounters between two distinct teams at a venue."],
    ["12", "participant", "Stores individual athlete lineup submissions for specific tournament matches."],
    ["13", "result", "Records verified final scores, winning teams, and post-match remarks."],
    ["14", "equipment_issue", "Tracks sports equipment checkouts, return deadlines, and custody statuses."]
]
add_table("Table 5. Relational Schema", t5_headers, t5_rows, col_widths=[0.6, 1.8, 3.8])

add_section_title("2.2 Keys and Integrity Constraints")
t6_headers = ["Table Name", "Key / Constraint", "Attribute(s)", "Business Rule Enforced"]
t6_rows = [
    ["membership_plan", "Primary Key\nUnique Key\nCheck\nCheck", "plan_id\nplan_name\nduration_months\nfee", "Entity identity.\nPrevents duplicate plan naming.\nduration_months > 0 enforces positive duration.\nfee >= 0.00 ensures valid pricing."],
    ["member", "Primary Key\nUnique Key\nUnique Key\nForeign Key\nCheck", "member_id\nphone\nemail\nplan_id\nmembership_end", "Entity identity.\nUnique mobile contact across patrons.\nUnique email address.\nReferences membership_plan(plan_id) (ON DELETE RESTRICT).\nmembership_end >= membership_start prevents invalid date sequences."],
    ["payment", "Primary Key\nForeign Key\nForeign Key\nCheck", "payment_id\nmember_id\nplan_id\namount", "Financial receipt identity.\nReferences member(member_id) (ON DELETE RESTRICT).\nReferences membership_plan(plan_id) (ON DELETE RESTRICT).\namount > 0.00 ensures non-zero positive transactions."],
    ["sport", "Primary Key\nUnique Key\nCheck", "sport_id\nsport_name\nmax_team_size", "Discipline identity.\nUnique sport nomenclature.\nmax_team_size > 0 guarantees positive squad limit."],
    ["coach", "Primary Key\nUnique Key\nForeign Key", "coach_id\nphone\nsport_id", "Instructor identity.\nUnique coach contact number.\nReferences sport(sport_id) (ON DELETE RESTRICT)."],
    ["team", "Primary Key\nUnique Key\nForeign Key\nForeign Key", "team_id\nteam_name\nsport_id\ncoach_id", "Team identity.\nUnique franchise name.\nReferences sport(sport_id) (ON DELETE RESTRICT).\nReferences coach(coach_id) (ON DELETE SET NULL)."],
    ["team_member", "Primary Key\nUnique Key\nForeign Key\nForeign Key", "team_member_id\nteam_id, member_id\nteam_id\nmember_id", "Roster entry identity.\nPrevents adding same member twice to one team.\nReferences team(team_id) (ON DELETE CASCADE).\nReferences member(member_id) (ON DELETE RESTRICT)."],
    ["facility", "Primary Key\nUnique Key\nCheck", "facility_id\nfacility_name\ncapacity", "Venue identity.\nUnique venue name.\ncapacity > 0 guarantees non-zero spectator/player threshold."],
    ["training_session", "Primary Key\nCheck\nCheck\nForeign Keys", "session_id\nend_time\nmax_attendees\nteam_id, coach_id, facility_id", "Session identity.\nend_time > start_time ensures positive duration.\nmax_attendees > 0 ensures positive attendance.\nReferences team, coach, facility (ON DELETE RESTRICT)."],
    ["tournament", "Primary Key\nCheck\nForeign Key", "tournament_id\nend_date\nsport_id", "Championship identity.\nend_date >= start_date guarantees chronological coherence.\nReferences sport(sport_id) (ON DELETE RESTRICT)."],
    ["fixture", "Primary Key\nCheck\nCheck\nForeign Keys", "fixture_id\nteam1_id, team2_id\nend_time\ntournament_id, facility_id, team1_id, team2_id", "Match identity.\nteam1_id <> team2_id prevents self-matches.\nend_time > start_time ensures valid match window.\ntournament_id (CASCADE); venues/teams (RESTRICT)."],
    ["participant", "Primary Key\nUnique Key\nForeign Keys", "participant_id\nfixture_id, member_id\nfixture_id, team_id, member_id", "Match lineup entry identity.\nA player can be submitted once per match.\nfixture_id (CASCADE); team/member (RESTRICT)."],
    ["result", "Primary Key\nUnique Key\nCheck\nCheck\nForeign Keys", "result_id\nfixture_id\nteam1_score\nteam2_score\nfixture_id, winner_team_id", "Result identity.\nStrict 1:1 relation with fixture.\nteam1_score >= 0 prohibits negative points.\nteam2_score >= 0 prohibits negative points.\nfixture_id (CASCADE); winner_team_id (RESTRICT)."],
    ["equipment_issue", "Primary Key\nCheck\nCheck\nForeign Key", "issue_id\nquantity\ndue_date\nmember_id", "Custody record identity.\nquantity > 0 prohibits zero checkouts.\ndue_date >= issue_date guarantees return window.\nReferences member(member_id) (ON DELETE RESTRICT)."]
]
add_table("Table 6. Keys and Integrity Constraints", t6_headers, t6_rows, col_widths=[1.4, 1.2, 1.6, 2.0])

add_section_title("2.3 Functional Dependencies")
add_body("The relational schema is governed by the following functional dependencies across all fourteen relations:")
add_bullet("plan_id -> {plan_name, duration_months, fee, benefits}; plan_name -> {plan_id, duration_months, fee, benefits}", bold_prefix="membership_plan: ")
add_bullet("member_id -> {name, phone, email, dob, join_date, plan_id, membership_start, membership_end, status}; phone -> {all}; email -> {all}", bold_prefix="member: ")
add_bullet("payment_id -> {member_id, plan_id, amount, payment_date, mode, status}", bold_prefix="payment: ")
add_bullet("sport_id -> {sport_name, category, max_team_size}; sport_name -> {sport_id, category, max_team_size}", bold_prefix="sport: ")
add_bullet("coach_id -> {name, phone, specialization, sport_id}; phone -> {coach_id, name, specialization, sport_id}", bold_prefix="coach: ")
add_bullet("team_id -> {team_name, sport_id, coach_id, formed_on}; team_name -> {team_id, sport_id, coach_id, formed_on}", bold_prefix="team: ")
add_bullet("team_member_id -> {team_id, member_id, role, joined_on}; {team_id, member_id} -> {team_member_id, role, joined_on}", bold_prefix="team_member: ")
add_bullet("facility_id -> {facility_name, type, capacity, status}; facility_name -> {facility_id, type, capacity, status}", bold_prefix="facility: ")
add_bullet("session_id -> {team_id, coach_id, facility_id, session_date, start_time, end_time, max_attendees}", bold_prefix="training_session: ")
add_bullet("tournament_id -> {tournament_name, sport_id, start_date, end_date}", bold_prefix="tournament: ")
add_bullet("fixture_id -> {tournament_id, facility_id, team1_id, team2_id, fixture_date, start_time, end_time, status}", bold_prefix="fixture: ")
add_bullet("participant_id -> {fixture_id, team_id, member_id, role}; {fixture_id, member_id} -> {participant_id, team_id, role}", bold_prefix="participant: ")
add_bullet("result_id -> {fixture_id, team1_score, team2_score, winner_team_id, remarks}; fixture_id -> {all result attributes}", bold_prefix="result: ")
add_bullet("issue_id -> {member_id, equipment_name, quantity, issue_date, due_date, return_date, status}", bold_prefix="equipment_issue: ")

add_section_title("2.4 Normalization up to Third Normal Form (3NF)")
add_body(
    "Every relation was rigorously verified against first, second, and third normal forms, as well as Boyce-Codd Normal Form (BCNF):\n"
    "• 1NF Conformance: All attribute domains are atomic. Multi-valued repeating groups (e.g. equipment loans, squad rosters) are segregated into dedicated tables.\n"
    "• 2NF Conformance: In composite candidate key tables (team_member, participant), all non-prime attributes functionally depend on the entire candidate key, eliminating partial dependencies.\n"
    "• 3NF & BCNF Conformance: For every non-trivial functional dependency X -> Y, X is a superkey. No transitive dependencies exist between non-prime attributes. Derived attributes (such as tournament points, goal difference, and fee arrears) are computed dynamically via database views."
)
t7_headers = ["Relation Name", "1NF", "2NF", "3NF", "BCNF", "Remarks / Decomposition"]
t7_rows = [
    ["membership_plan", "Yes", "Yes", "Yes", "Yes", "Fully normalized tier attributes. Determinants are superkeys."],
    ["member", "Yes", "Yes", "Yes", "Yes", "Decomposed from plan fee and duration; references plan_id."],
    ["payment", "Yes", "Yes", "Yes", "Yes", "Decomposed from member personal details; pure transaction ledger."],
    ["sport", "Yes", "Yes", "Yes", "Yes", "Atomic discipline metadata."],
    ["coach", "Yes", "Yes", "Yes", "Yes", "Decomposed from sport metadata; references sport_id."],
    ["team", "Yes", "Yes", "Yes", "Yes", "Distinct team identity; separated from roster members."],
    ["team_member", "Yes", "Yes", "Yes", "Yes", "Normalized associative table resolving M:N relationship."],
    ["facility", "Yes", "Yes", "Yes", "Yes", "Atomic physical venue catalog."],
    ["training_session", "Yes", "Yes", "Yes", "Yes", "Practice reservation entity; venue and coach normalized via FKs."],
    ["tournament", "Yes", "Yes", "Yes", "Yes", "Event lifecycle entity; separate from individual match fixtures."],
    ["fixture", "Yes", "Yes", "Yes", "Yes", "Match scheduling entity; separated from post-match results."],
    ["participant", "Yes", "Yes", "Yes", "Yes", "Associative entity mapping player lineups per fixture."],
    ["result", "Yes", "Yes", "Yes", "Yes", "1:1 post-match audit entity; points computed dynamically."],
    ["equipment_issue", "Yes", "Yes", "Yes", "Yes", "Individual loan checkout record; member normalized via FK."]
]
add_table("Table 7. Normalization Status up to 3NF", t7_headers, t7_rows, col_widths=[1.5, 0.6, 0.6, 0.6, 0.6, 2.3])

add_section_title("2.5 Data Dictionary")
t8_headers = ["Table", "Attribute", "Data Type", "Key / Constraint", "Description"]
t8_rows = [
    ["membership_plan", "plan_id", "INT", "PK, AUTO_INCREMENT", "Unique surrogate identifier for plan tier."],
    ["membership_plan", "plan_name", "VARCHAR(100)", "NOT NULL, UNIQUE", "Human-readable package tier name."],
    ["membership_plan", "duration_months", "INT", "NOT NULL, CHECK > 0", "Validity duration in calendar months."],
    ["membership_plan", "fee", "DECIMAL(10,2)", "NOT NULL, CHECK >= 0", "Standard price charged for the tier."],
    ["membership_plan", "benefits", "TEXT", "NULL", "Summary of facilities and entitlements."],
    ["member", "member_id", "INT", "PK, AUTO_INCREMENT", "Unique patron identification number."],
    ["member", "name", "VARCHAR(100)", "NOT NULL", "Full personal name of club member."],
    ["member", "phone", "VARCHAR(20)", "NOT NULL, UNIQUE", "Contact phone number."],
    ["member", "email", "VARCHAR(120)", "NOT NULL, UNIQUE", "Primary email address."],
    ["member", "dob", "DATE", "NOT NULL", "Date of birth for age verification."],
    ["member", "join_date", "DATE", "NOT NULL, DEFAULT CURDATE", "Date the member initially registered."],
    ["member", "plan_id", "INT", "FK -> membership_plan", "Subscribed membership package tier."],
    ["member", "membership_start", "DATE", "NOT NULL", "Current active cycle start date."],
    ["member", "membership_end", "DATE", "NOT NULL, CHECK >= start", "Current active cycle expiration date."],
    ["member", "status", "ENUM", "'Active','Expired','Suspended'", "Account standing status."],
    ["payment", "payment_id", "INT", "PK, AUTO_INCREMENT", "Unique accounting receipt identifier."],
    ["payment", "member_id", "INT", "FK -> member", "Member remitting payment."],
    ["payment", "plan_id", "INT", "FK -> membership_plan", "Subscription tier being purchased."],
    ["payment", "amount", "DECIMAL(10,2)", "NOT NULL, CHECK > 0", "Transaction monetary amount."],
    ["payment", "payment_date", "DATE", "NOT NULL, DEFAULT CURDATE", "Timestamp date of remittance."],
    ["payment", "mode", "ENUM", "'Cash','UPI','Card','Bank'", "Financial payment channel."],
    ["payment", "status", "ENUM", "'Paid','Pending'", "Settlement state."],
    ["sport", "sport_id", "INT", "PK, AUTO_INCREMENT", "Unique sport identifier."],
    ["sport", "sport_name", "VARCHAR(80)", "NOT NULL, UNIQUE", "Official sporting discipline title."],
    ["sport", "category", "ENUM", "'Team','Individual'", "Classification structure."],
    ["sport", "max_team_size", "INT", "NOT NULL, CHECK > 0", "Maximum allowed roster squad size."],
    ["coach", "coach_id", "INT", "PK, AUTO_INCREMENT", "Unique coaching staff identifier."],
    ["coach", "name", "VARCHAR(100)", "NOT NULL", "Full name of trainer/coach."],
    ["coach", "phone", "VARCHAR(20)", "NOT NULL, UNIQUE", "Coach emergency contact phone."],
    ["coach", "specialization", "VARCHAR(100)", "NULL", "Technical coaching tactical domain."],
    ["coach", "sport_id", "INT", "FK -> sport", "Sport discipline certified in."],
    ["team", "team_id", "INT", "PK, AUTO_INCREMENT", "Unique team franchise identifier."],
    ["team", "team_name", "VARCHAR(100)", "NOT NULL, UNIQUE", "Unique club squad name."],
    ["team", "sport_id", "INT", "FK -> sport", "Sport discipline contested."],
    ["team", "coach_id", "INT", "FK -> coach, NULL", "Assigned head coach."],
    ["team", "formed_on", "DATE", "NOT NULL, DEFAULT CURDATE", "Squad establishment date."],
    ["team_member", "team_member_id", "INT", "PK, AUTO_INCREMENT", "Unique roster entry identifier."],
    ["team_member", "team_id", "INT", "FK -> team, UNIQUE(team,mem)", "Team roster being joined."],
    ["team_member", "member_id", "INT", "FK -> member", "Active member player."],
    ["team_member", "role", "VARCHAR(50)", "DEFAULT 'Player'", "Squad tactical role."],
    ["facility", "facility_id", "INT", "PK, AUTO_INCREMENT", "Venue identification number."],
    ["facility", "facility_name", "VARCHAR(100)", "NOT NULL, UNIQUE", "Physical venue or court designation."],
    ["facility", "type", "VARCHAR(60)", "NOT NULL", "Surface/ground type description."],
    ["facility", "capacity", "INT", "NOT NULL, CHECK > 0", "Maximum spectator/player capacity."],
    ["facility", "status", "ENUM", "'Available','Maintenance'", "Current operational readiness."],
    ["training_session", "session_id", "INT", "PK, AUTO_INCREMENT", "Unique practice session identifier."],
    ["training_session", "team_id", "INT", "FK -> team", "Squad participating in drill."],
    ["training_session", "coach_id", "INT", "FK -> coach", "Supervising coach."],
    ["training_session", "facility_id", "INT", "FK -> facility", "Reserved venue court."],
    ["training_session", "session_date", "DATE", "NOT NULL", "Calendar date of session."],
    ["training_session", "start_time", "TIME", "NOT NULL", "Scheduled start clock time."],
    ["training_session", "end_time", "TIME", "NOT NULL, CHECK > start", "Scheduled completion clock time."],
    ["training_session", "max_attendees", "INT", "NOT NULL, CHECK > 0", "Maximum player attendance cap."],
    ["tournament", "tournament_id", "INT", "PK, AUTO_INCREMENT", "Unique tournament identifier."],
    ["tournament", "tournament_name", "VARCHAR(120)", "NOT NULL", "Official championship title."],
    ["tournament", "sport_id", "INT", "FK -> sport", "Sporting discipline contested."],
    ["tournament", "start_date", "DATE", "NOT NULL", "Tournament opening date."],
    ["tournament", "end_date", "DATE", "NOT NULL, CHECK >= start", "Tournament conclusion date."],
    ["fixture", "fixture_id", "INT", "PK, AUTO_INCREMENT", "Unique match fixture identifier."],
    ["fixture", "tournament_id", "INT", "FK -> tournament", "Governing championship."],
    ["fixture", "facility_id", "INT", "FK -> facility", "Venue staging the match."],
    ["fixture", "team1_id", "INT", "FK -> team, CHECK != team2", "Designated home team competitor."],
    ["fixture", "team2_id", "INT", "FK -> team", "Designated away team competitor."],
    ["fixture", "fixture_date", "DATE", "NOT NULL", "Match calendar date."],
    ["fixture", "start_time", "TIME", "NOT NULL", "Scheduled kickoff/start time."],
    ["fixture", "end_time", "TIME", "NOT NULL, CHECK > start", "Scheduled match conclusion time."],
    ["fixture", "status", "ENUM", "'Scheduled','Completed','Cancelled'", "Match execution status."],
    ["participant", "participant_id", "INT", "PK, AUTO_INCREMENT", "Match lineup entry identifier."],
    ["participant", "fixture_id", "INT", "FK -> fixture, UNIQUE(fix,mem)", "Match being contested."],
    ["participant", "team_id", "INT", "FK -> team", "Team squad represented."],
    ["participant", "member_id", "INT", "FK -> member", "Active player member."],
    ["result", "result_id", "INT", "PK, AUTO_INCREMENT", "Result audit record identifier."],
    ["result", "fixture_id", "INT", "FK -> fixture, UNIQUE", "Contested match (1:1 relation)."],
    ["result", "team1_score", "INT", "NOT NULL, CHECK >= 0", "Final score points scored by Team 1."],
    ["result", "team2_score", "INT", "NOT NULL, CHECK >= 0", "Final score points scored by Team 2."],
    ["result", "winner_team_id", "INT", "FK -> team, NULL", "Victorious team ID (NULL for draw)."],
    ["equipment_issue", "issue_id", "INT", "PK, AUTO_INCREMENT", "Equipment loan identifier."],
    ["equipment_issue", "member_id", "INT", "FK -> member", "Borrowing active member."],
    ["equipment_issue", "equipment_name", "VARCHAR(100)", "NOT NULL", "Specific sporting gear item name."],
    ["equipment_issue", "quantity", "INT", "NOT NULL, CHECK > 0", "Number of units checked out."],
    ["equipment_issue", "issue_date", "DATE", "NOT NULL, DEFAULT CURDATE", "Date checked out of inventory."],
    ["equipment_issue", "due_date", "DATE", "NOT NULL, CHECK >= issue", "Deadline date for equipment return."],
    ["equipment_issue", "status", "ENUM", "'Issued','Returned','Overdue'", "Current custody loan status."]
]
add_table("Table 8. Data Dictionary", t8_headers, t8_rows, col_widths=[1.2, 1.2, 1.0, 1.4, 1.4])

add_section_title("2.6 Implementation of Logical Design: DDL and Sample Data")
t9_headers = ["Item", "Details"]
t9_rows = [
    ["DBMS", "MySQL Community Server 8.0"],
    ["DBMS Version", "8.0.46 for Win64 (x86_64)"],
    ["Storage Engine", "InnoDB (Row-level locking, foreign keys, ACID compliance)"],
    ["Character Set / Collation", "utf8mb4 / utf8mb4_unicode_ci"],
    ["Number of Tables", "14 Relations"],
    ["Number of Triggers", "8 Active Business Rule Triggers"],
    ["Number of Stored Procedures", "6 Transactional Procedures & Routines"],
    ["Number of Views", "8 Operational & Analytical Views"],
    ["Sample Data", "5 Plans, 35 Members, 35 Payments, 6 Sports, 8 Coaches, 10 Teams, 42 Roster entries, 7 Facilities, 25 Sessions, 3 Tournaments, 20 Fixtures, 12 Results, 42 Match Participants, 25 Equipment Checkouts."]
]
add_table("Table 9. Database Implementation Environment", t9_headers, t9_rows, col_widths=[2.4, 3.8])

add_subsection_title("Representative DDL Implementation Snippets")
ddl_snippet = """-- DDL Example 1: Member Table with Date Order Check and Restrict Cascades
CREATE TABLE member (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(120) NOT NULL UNIQUE,
    dob DATE NOT NULL,
    join_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    plan_id INT NOT NULL,
    membership_start DATE NOT NULL,
    membership_end DATE NOT NULL,
    status ENUM('Active', 'Expired', 'Suspended') NOT NULL DEFAULT 'Active',
    CONSTRAINT chk_member_dates CHECK (membership_end >= membership_start),
    CONSTRAINT fk_member_plan FOREIGN KEY (plan_id)
        REFERENCES membership_plan(plan_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- DDL Example 2: Fixture Table with Strict Team Separation and Cascading Lifecycle
CREATE TABLE fixture (
    fixture_id INT AUTO_INCREMENT PRIMARY KEY,
    tournament_id INT NOT NULL,
    facility_id INT NOT NULL,
    team1_id INT NOT NULL,
    team2_id INT NOT NULL,
    fixture_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status ENUM('Scheduled', 'Completed', 'Cancelled') NOT NULL DEFAULT 'Scheduled',
    CONSTRAINT chk_fixture_teams CHECK (team1_id <> team2_id),
    CONSTRAINT chk_fixture_time CHECK (end_time > start_time),
    CONSTRAINT fk_fix_tourn FOREIGN KEY (tournament_id)
        REFERENCES tournament(tournament_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_fix_facility FOREIGN KEY (facility_id)
        REFERENCES facility(facility_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_fix_team1 FOREIGN KEY (team1_id)
        REFERENCES team(team_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT fk_fix_team2 FOREIGN KEY (team2_id)
        REFERENCES team(team_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE=InnoDB;"""
add_code(ddl_snippet)

doc.add_page_break()

# =========================================================================
# CHAPTER 3 (Pages 16-18)
# =========================================================================
add_chapter_title("CHAPTER 3")
add_chapter_title("APPLICATION DEVELOPMENT USING LOGICAL DATABASE DESIGN")

add_section_title("3.1 Application Overview")
add_body(
    "The web application provides an administrative platform built with Python 3.10 and the Flask framework. The application "
    "interfaces with the database via connection pooling and executes parameterized queries across all modules. It includes "
    "server-side input sanitization, an interactive venue conflict checker, and a reporting suite that renders and exports eight "
    "live database views as CSV files."
)

add_section_title("3.2 Development Environment and Database Connectivity")
t10_headers = ["Item", "Details"]
t10_rows = [
    ["Programming Language", "Python 3.10.20"],
    ["DBMS", "MySQL Community Server 8.0.46"],
    ["Web Framework", "Flask 3.1.3 (WSGI micro-framework, Jinja2 templating)"],
    ["Frontend Styling", "Custom CSS3 (Dark sidebar, glassmorphic UI) + Bootstrap 5.3.3 CDN"],
    ["Database Connector / Driver", "mysql-connector-python with connection pooling"],
    ["Testing Framework", "pytest 9.1.1 + Native MySQL Stored Test Procedure Harness"],
    ["Operating Environment", "Windows 11 Enterprise (64-bit), PowerShell Shell"],
    ["Configuration Architecture", "Decoupled .env configuration file via python-dotenv"],
    ["Repository Directory", "d:\\dbms project\\sports_club_dbms"]
]
add_table("Table 10. Application Development Environment", t10_headers, t10_rows, col_widths=[2.4, 3.8])

add_section_title("3.3 Application Modules and Database Mapping")
t11_headers = ["Module / Screen", "Purpose", "Tables Used", "Main Operations"]
t11_rows = [
    ["1. Dashboard", "High-level summary of active members, matches, overdue loans, revenue.", "member, team, fixture, equipment_issue, payment", "Aggregates, multi-table joins, LIMIT queries."],
    ["2. Memberships", "Member directory, search/filters, registration modal, renewal.", "member, membership_plan, payment", "Parameterized SELECT, sp_register_member_with_payment."],
    ["3. Team Formation", "Squad creation, sport alignment, roster management.", "team, sport, coach, team_member, member", "INSERT team, roster enrollment/removal, progress meters."],
    ["4. Training Scheduling", "Scheduling team practice sessions and drills.", "training_session, team, coach, facility, sport", "Non-overlapping session INSERT with trigger validation."],
    ["5. Facilities & Booking", "Venue catalog and real-time conflict diagnostic checker.", "facility, training_session, fixture, team", "Cross-table interval overlap queries, JSON AJAX API."],
    ["6. Match Fixtures", "Scheduling championship matches between squads.", "fixture, tournament, facility, team, sport", "Multi-table join listings, distinct team INSERT."],
    ["7. Result Entry", "Match score submission and championship finalization.", "result, fixture, team, tournament", "Score submission calling sp_enter_result, auto status update."],
    ["8. Fee Collection", "Financial transaction recording and fee ledger audits.", "payment, member, membership_plan", "Transaction logging, status filtering (Paid vs Pending)."],
    ["9. Equipment Inventory", "Gear checkouts, due date tracking, returns.", "equipment_issue, member", "Calling sp_issue_equipment, sp_return_equipment."],
    ["10. Analytics & Reports", "Dynamic rendering of all 8 database views with CSV export.", "All 8 Views (v_tournament_standings, etc.)", "Dynamic view querying, CSV stream serialization."]
]
add_table("Table 11. Application Module-to-Database Mapping", t11_headers, t11_rows, col_widths=[1.5, 1.7, 1.5, 1.5])

add_section_title("3.4 CRUD Operations")
t12_headers = ["Operation", "Application Feature / Screen", "Table(s) Affected", "Evidence / Implementation"]
t12_rows = [
    ["Create (C)", "• Member Registration\n• Team Formation\n• Schedule Fixture\n• Issue Equipment", "member, payment\nteam\nfixture\nequipment_issue", "Atomic procedure sp_register_member_with_payment.\nParameterized INSERT into team.\nParameterized INSERT into fixture.\nStored procedure sp_issue_equipment."],
    ["Read / Search (R)", "• Member Directory Filter\n• Upcoming Fixtures List\n• Live Conflict Checker\n• Operational Views", "member, membership_plan\nfixture, tournament, team\nfacility, training_session\nAll 8 Database Views", "Parameterized query with %LIKE% across name/email/phone.\n4-table INNER JOIN with WHERE status='Scheduled'.\nCross-table temporal overlap search via AJAX.\nSELECT * FROM v_tournament_standings."],
    ["Update (U)", "• Member Renewal\n• Enter Match Result\n• Equipment Return", "member, payment\nresult, fixture\nequipment_issue", "Calling sp_renew_membership updating validity end date.\nCalling sp_enter_result setting fixture to 'Completed'.\nCalling sp_return_equipment setting status to 'Returned'."],
    ["Delete (D)", "• Remove Player from Squad\n• Test Rollback Cleanup", "team_member\ntest_results", "Controlled removal via DELETE FROM team_member WHERE team_id=%s AND member_id=%s."]
]
add_table("Table 12. CRUD Operations", t12_headers, t12_rows, col_widths=[1.3, 1.7, 1.5, 1.7])

add_section_title("3.5 Business Rules, Validation and Error Handling")
t13_headers = ["Rule / Validation", "How Implemented", "Evidence / Message"]
t13_rows = [
    ["Rule 1: Facility Overlap", "Database triggers trg_training_session_before_insert and trg_fixture_before_insert check interval overlap (start < new_end AND end > new_start) across both tables.", "SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Facility schedule conflict: Facility is already booked during this time interval.';"],
    ["Rule 2: Team Overlap", "Triggers check if team_id or team1_id/team2_id has an existing session or fixture at overlapping times.", "SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Team schedule conflict: Team has another session or fixture during this time interval.';"],
    ["Rule 3: Active Member", "Triggers on team_member, participant, and equipment_issue check status = 'Active' and membership_end >= CURDATE().", "SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Active membership required: Member is not Active or membership has expired.';"],
    ["Rule 4: Valid Scores & Winner", "Trigger trg_result_before_insert checks team1_score >= 0, team2_score >= 0, verifies winner_team_id matches higher score or NULL on tie.", "SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Result validation error: winner_team_id must match higher scoring team or NULL for draw.';"],
    ["Rule 5: Capacity Ceilings", "Trigger on team_member counts current squad size against sport.max_team_size; checks attendees against venue capacity.", "SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Capacity exceeded: Team roster has reached the maximum size for this sport.';"],
    ["Rule 6: Equipment Quotas", "Trigger on equipment_issue blocks checkout if unreturned items + new > 3 or if any loan is overdue.", "SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Equipment limit exceeded: Member cannot hold more than 3 unreturned equipment items.';"],
    ["Rule 7: Facility Maintenance", "Triggers verify facility.status = 'Available'.", "SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Facility unavailable: Selected facility is under maintenance.';"],
    ["Rule 8: Sport Consistency", "Triggers verify coach's sport matches team's sport, and competing teams match tournament sport.", "SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sport mismatch: Teams must belong to the same sport as the tournament.';"],
    ["Application Sanitization", "clean_db_error() in db.py parses MySQL exceptions, stripping technical codes and displaying clean alert banners.", "User-friendly alert banner displayed in UI: 'Facility schedule conflict: Facility is already booked...'"]
]
add_table("Table 13. Business Rules, Validation and Error Handling", t13_headers, t13_rows, col_widths=[1.5, 2.3, 2.4])

add_section_title("3.6 Reports and Database Operations")
t14_headers = ["Report / Operation", "SQL / Database Concept Used", "Application Output"]
t14_rows = [
    ["1. Active Memberships", "View v_active_memberships: INNER JOIN with temporal computation DATEDIFF(membership_end, CURDATE()).", "Table of active patrons, current subscription tier, and countdown of days remaining."],
    ["2. Expiring Subscriptions", "View v_membership_expiring_30_days: Date interval filtering BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY).", "Actionable table of members up for renewal in the next 30 days."],
    ["3. Master Fixture Schedule", "View v_fixture_schedule: 5-table INNER/LEFT JOIN combining tournaments, venues, squads, and results.", "Master calendar of upcoming and completed matches with venue and scores."],
    ["4. Tournament Standings", "View v_tournament_standings: Multi-team UNION, conditional aggregations for W/D/L, GD, 3-1-0 points, and RANK() OVER.", "Official championship standings table with goal difference, points, and league rank."],
    ["5. Venue Utilization", "View v_facility_utilization: Correlated subqueries aggregating training drills and competitive matches per venue.", "Venue usage comparison table contrasting practice sessions versus tournament matches."],
    ["6. Player Performance", "View v_player_performance: Multi-table JOIN grouping match rosters and counting appearances and squad victories.", "Individual player match ledger tracking appearances, wins, draws, and losses."],
    ["7. Fee Dues & Arrears", "View v_fee_dues: LEFT JOIN with pending payment aggregations and status filtering (status = 'Expired').", "Accounts receivable report highlighting patrons with pending fees or expired memberships."],
    ["8. Equipment Status", "View v_equipment_status: Conditional SUM(CASE WHEN ...) aggregations across checkouts per member.", "Custody audit summary showing total issued, returned, and overdue items per patron."]
]
add_table("Table 14. Reports and Database Operations", t14_headers, t14_rows, col_widths=[1.6, 2.3, 2.3])

add_section_title("3.7 Application Screens")
add_body(
    "The application features a responsive user interface built using modern CSS3 and Bootstrap 5 CDN. Key functional interfaces "
    "demonstrating data entry, search, update, transaction processing, and reports are documented below in Figures 2 through 5:"
)
add_figure("fig2_dashboard.png", "Figure 2. Dashboard and Operational Metrics Screen", width_in=5.8)
add_figure("fig3_members.png", "Figure 3. Member Registration and Profile Management Screen", width_in=5.8)
add_figure("fig4_fixtures.png", "Figure 4. Match Fixture Scheduling and Live Conflict Checker Screen", width_in=5.8)
add_figure("fig5_results.png", "Figure 5. Match Results Entry and Standings Reporting Screen", width_in=5.8)

add_section_title("3.8 Testing and Results")
add_body(
    "Testing was conducted across two complementary frameworks:\n"
    "1. Automated SQL Constraint Test Harness (test_constraints.sql): Validated all database constraints and triggers directly inside MySQL 8, executing 13 negative (failing) test cases and 13 positive (passing) test cases.\n"
    "2. Pytest Integration Suite (test_app.py): Validated form input validators, HTTP routes, JSON APIs, and CSV downloads."
)
t15_headers = ["Test ID", "Feature", "Input / Action", "Expected Result", "Actual Result", "Status"]
t15_rows = [
    ["TC-01", "Plan Pricing Check", "Insert plan with negative fee (-500.00)", "Rejected by chk_plan_fee", "Blocked by CHECK constraint", "PASS"],
    ["TC-02", "Membership Dates", "Member with end_date < start_date", "Rejected by chk_member_dates", "Blocked by CHECK constraint", "PASS"],
    ["TC-03", "Distinct Teams", "Fixture with team1_id = team2_id", "Rejected by chk_fixture_teams", "Blocked by CHECK constraint", "PASS"],
    ["TC-04", "Phone Uniqueness", "Member with existing registered phone", "Rejected by UNIQUE(phone)", "Blocked by UNIQUE key", "PASS"],
    ["TC-05", "Plan Foreign Key", "Member referencing non-existent plan ID 9999", "Rejected by fk_member_plan", "Blocked by FK constraint", "PASS"],
    ["TC-06", "Venue Collision", "Book Facility 1 during existing session", "Trigger signals schedule conflict", "Blocked by Trigger", "PASS"],
    ["TC-07", "Team Collision", "Book Team 1 for concurrent session", "Trigger signals squad conflict", "Blocked by Trigger", "PASS"],
    ["TC-08", "Inactive Member", "Expired member joins squad roster", "Trigger signals active required", "Blocked by Trigger", "PASS"],
    ["TC-09", "Winner Consistency", "Score 10-5 entered with team 2 as winner", "Trigger signals winner mismatch", "Blocked by Trigger", "PASS"],
    ["TC-10", "Squad Capacity", "Add 5th player to Badminton team (max 4)", "Trigger signals roster full", "Blocked by Trigger", "PASS"],
    ["TC-11", "Overdue Gear Check", "Member with overdue item borrows gear", "Trigger signals overdue block", "Blocked by Trigger", "PASS"],
    ["TC-12", "Venue Maintenance", "Book session on facility under Maintenance", "Trigger signals unavailable", "Blocked by Trigger", "PASS"],
    ["TC-13", "Sport Consistency", "Schedule Football team in Cricket tournament", "Trigger signals sport mismatch", "Blocked by Trigger", "PASS"],
    ["TC-14", "Email Validation", "Input malformed email string user@bad", "Validator rejects address format", "Rejected with error", "PASS"],
    ["TC-15", "CSV View Export", "GET /reports/export/tournament_standings", "Returns HTTP 200, MIME text/csv", "CSV streamed with headers", "PASS"]
]
add_table("Table 15. Test Cases", t15_headers, t15_rows, col_widths=[0.8, 1.2, 1.4, 1.2, 1.1, 0.5])

add_subsection_title("Key Results and Observations")
add_body(
    "1. 100% Pass Rate: All 26 SQL constraint tests (13 negative assertions, 13 positive assertions) and all 21 pytest test assertions passed without regression.\n"
    "2. Declarative Business Rule Enforcement: Every business rule reliably blocked invalid operations at the database engine tier, independent of frontend code execution.\n"
    "3. Data Integrity: Cascading actions cleanly maintained data consistency while ON DELETE RESTRICT preserved critical financial and member audit trails.\n"
    "4. Optimized Query Execution: B-tree indexes on composite scheduling keys eliminated full table scans, enabling sub-millisecond conflict checks and instant report generation."
)

doc.add_page_break()

# =========================================================================
# CHAPTER 4 (Page 19)
# =========================================================================
add_chapter_title("CHAPTER 4")
add_chapter_title("CONCLUSION")

add_body(
    "This project successfully designed, implemented, and validated an enterprise-grade Database Management System for sports club membership, "
    "facility scheduling, and tournament operations. By mapping business requirements to a normalized relational architecture across "
    "fourteen tables in 3NF and BCNF, the system eliminates data redundancy and update anomalies. Enforcing business rules directly within "
    "MySQL 8 using declarative triggers and transactional stored procedures guarantees ACID compliance and protects system data integrity "
    "against concurrent scheduling collisions and quota breaches. The Python Flask web application demonstrates full integration between "
    "logical database design and administrative user workflows, featuring parameterized CRUD modules, an interactive venue conflict checker, "
    "and automated analytical reports with instant CSV downloads."
)

add_section_title("4.1 Limitations and Future Enhancements")
add_bullet(" The current implementation tracks settlement states (Paid/Pending) within the database ledger; integrating live payment gateway webhooks (e.g., Razorpay or Stripe) would enable automated real-time fee capture.", bold_prefix="Third-Party Payment Gateway Integration:")
add_bullet(" The current workflow allows administrators to schedule fixtures manually; implementing round-robin and knockout tournament seeding algorithms would further streamline competition management.", bold_prefix="Automated Tournament Fixture Generator:")
add_bullet(" Incorporating hardware scanners for sports equipment checkouts would enable automated tracking of gear custody across facility checkout desks.", bold_prefix="RFID / Barcode Hardware Integration:")

doc.add_page_break()

# =========================================================================
# 5. REFERENCES (Pages 20-21 format)
# =========================================================================
add_chapter_title("5. REFERENCES")

refs = [
    "[1] R. Elmasri and S. B. Navathe, Fundamentals of Database Systems, 7th ed. Boston, MA, USA: Pearson, 2017.",
    "[2] A. Silberschatz, H. F. Korth, and S. Sudarshan, Database System Concepts, 7th ed. New York, NY, USA: McGraw-Hill, 2020.",
    "[3] C. J. Date, An Introduction to Database Systems, 8th ed. Boston, MA, USA: Addison-Wesley, 2004.",
    "[4] Oracle Corporation, \"MySQL 8.0 Reference Manual,\" 2026. [Online]. Available: https://dev.mysql.com/doc/refman/8.0/en/",
    "[5] P. DuBois, MySQL Cookbook: Solutions for Database Developers and Administrators, 4th ed. Sebastopol, CA, USA: O'Reilly Media, 2022.",
    "[6] Pallets Projects, \"Flask Documentation (Version 3.1.x),\" 2026. [Online]. Available: https://flask.palletsprojects.com/"
]
for ref in refs:
    p_ref = doc.add_paragraph()
    p_ref.paragraph_format.line_spacing = 1.5
    p_ref.paragraph_format.space_after = Pt(6)
    p_ref.paragraph_format.left_indent = Inches(0.3)
    p_ref.paragraph_format.first_line_indent = Inches(-0.3)
    r = p_ref.add_run(ref)
    r.font.name = 'Times New Roman'
    r.font.size = Pt(12)

doc.add_page_break()

# =========================================================================
# 6. APPENDICES (Page 22 format)
# =========================================================================
add_chapter_title("6. APPENDICES")

add_section_title("APPENDIX A - COMPLETE DATABASE SCRIPT")
add_body(
    "The complete SQL scripts containing all table schema definitions, constraints, indexes, triggers, stored procedures, sample data, "
    "analytical queries, and views have been organized and committed within the project repository under the sql/ folder:\n"
    "• sql/01_schema.sql: 14 relational tables, PKs, FKs, CHECK constraints, and 8 performance indexes.\n"
    "• sql/02_triggers.sql: 8 active business rule enforcement triggers (cross-table venue overlaps, team conflicts, quotas).\n"
    "• sql/03_procedures.sql: Transactional stored procedures with ACID compliance and scheduled daily maintenance routine.\n"
    "• sql/04_sample_data.sql: Complete realistic Indian athletic club dataset spanning all 14 tables.\n"
    "• sql/05_queries.sql: 27 comprehensive analytical and operational queries.\n"
    "• sql/06_views.sql: 8 live database views including dynamic tournament league standings.\n"
    "• tests/test_constraints.sql: Automated 26-assertion SQL test suite."
)

add_section_title("APPENDIX B - APPLICATION SOURCE CODE")
add_body(
    "The full-stack application source code is structured under the app/ folder and test harness:\n"
    "• app/app.py: Flask server application, controller endpoints, route handling, CSV serialization.\n"
    "• app/db.py: Database connection pooling and exception sanitization helper routines.\n"
    "• app/validators.py: Server-side validation rules for dates, emails, phones, and numeric inputs.\n"
    "• app/templates/: Jinja2 HTML templates for all modules (base, index, members, fixtures, results, reports, etc.).\n"
    "• app/static/: Custom CSS stylesheet and interactive JavaScript client scripts.\n"
    "• tests/test_app.py: Pytest automated test harness covering route responses and input validation."
)

add_section_title("APPENDIX C - ADDITIONAL TEST DATA AND OUTPUTS")
add_body(
    "Supplementary documentation, test logs, and mathematical normalization proofs are provided in the docs/ folder:\n"
    "• docs/normalization.md: Step-by-step mathematical proofs of 1NF -> 2NF -> 3NF/BCNF normalization.\n"
    "• docs/test_report.md: Complete execution matrix and outcome log for all 26 SQL constraint and 21 pytest test cases.\n"
    "• docs/er_diagram.mmd: Conceptual Mermaid Entity-Relationship diagram in Crow's Foot notation.\n"
    "• docs/project_report.md: Markdown source version of the project report."
)

print(f"Saving compiled .docx report to {DOCX_OUTPUT_PATH}...")
doc.save(DOCX_OUTPUT_PATH)
doc.save(DOCX_COPY_PATH)
print("Successfully generated both DOCX files!")
