# app.py

import io, textwrap
import streamlit as st
import os
import pandas as pd
from mcc import call_fracto, write_excel_from_ocr, _extract_rows, MAPPINGS

# ── Fracto branding styles ────────────────────────────────────
FRACTO_PRIMARY   = "#0066FF"   # adjust if brand palette differs
FRACTO_DARK      = "#003B9C"
FRACTO_LIGHT_BG  = "#F5F8FF"

st.markdown(f"""
    <style>
    /* Page background */
    .stApp {{
        background: {FRACTO_LIGHT_BG};
    }}
    /* Primary buttons */
    button[kind="primary"] {{
        background-color: {FRACTO_PRIMARY} !important;
        color: #fff !important;
        border: 0 !important;
    }}
    button[kind="primary"]:hover {{
        background-color: {FRACTO_DARK} !important;
        color: #fff !important;
    }}
    /* Header text color */
    h1 {{
        color: {FRACTO_DARK};
    }}
    </style>
""", unsafe_allow_html=True)

# Logo banner at the top
st.image("https://www.fracto.tech/logo.svg", width=180)

# ── Session keys ─────────────────────────────────────────────
if "excel_bytes" not in st.session_state:
    st.session_state["excel_bytes"] = None
if "excel_filename" not in st.session_state:
    st.session_state["excel_filename"] = ""
if "edited_excel_bytes" not in st.session_state:
    st.session_state["edited_excel_bytes"] = None
    st.session_state["edited_filename"] = ""

# Ensure FRACTO_API_KEY is available for mcc.call_fracto
if "FRACTO_API_KEY" in st.secrets:
    os.environ["FRACTO_API_KEY"] = st.secrets["FRACTO_API_KEY"]

# ── Page config ───────────────────────────────────────────────
st.set_page_config(page_title="PDF → Smart-OCR → Excel",
                   page_icon="📄", layout="wide")

st.markdown("## Smart‑OCR to ERP‑ready Excel")

# 1) Upload widget
pdf_file = st.file_uploader("Upload PDF", type=["pdf"])

# 2) Extra manual fields
st.subheader("Manual fields (applied to every row)")
manual_inputs = {}
for col in ["Part No.", "Manufacturer Country"]:
    if col in MAPPINGS:
        val = st.text_input(col)
        if val:
            manual_inputs[col] = val

# 3) Process button
run = st.button("Process PDF", disabled=pdf_file is None)

if run:
    if not pdf_file:
        st.warning("Please upload a PDF first.")
        st.stop()

    with st.spinner("Calling Fracto…"):
        pdf_bytes = pdf_file.read()
        result    = call_fracto(pdf_bytes, pdf_file.name)

        buffer = io.BytesIO()
        write_excel_from_ocr([result], buffer, overrides=manual_inputs)
        st.session_state["excel_bytes"]   = buffer.getvalue()
        st.session_state["excel_filename"] = pdf_file.name.replace(".pdf", "_ocr.xlsx")

    st.success("Excel generated! You can download or preview it below.")

# ── Download + Editable Preview section ───────────────────────
if st.session_state["excel_bytes"]:
    # 1) Download original
    st.download_button(
        "⬇️ Download original Excel",
        data=st.session_state["excel_bytes"],
        file_name=st.session_state["excel_filename"],
        mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        key="download_original",
    )

    # 2) Editable grid
    df = pd.read_excel(io.BytesIO(st.session_state["excel_bytes"]))
    edited_df = st.experimental_data_editor(
        df,
        num_rows="dynamic",
        use_container_width=True,
        key="editable_grid",
    )

    # 3) Save edits
    if st.button("💾 Save edits"):
        out_buf = io.BytesIO()
        edited_df.to_excel(out_buf, index=False, engine="openpyxl")
        st.session_state["edited_excel_bytes"] = out_buf.getvalue()
        st.session_state["edited_filename"] = st.session_state["excel_filename"].replace(
            ".xlsx", "_edited.xlsx"
        )
        st.success("Edits saved — scroll below to download the .xlsx file.")

    # 4) Download edited Excel (persistent button)
    if st.session_state["edited_excel_bytes"]:
        st.download_button(
            "⬇️ Download edited Excel",
            data=st.session_state["edited_excel_bytes"],
            file_name=st.session_state["edited_filename"],
            mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            key="download_edited",
        )