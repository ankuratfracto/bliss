# app.py

import io, textwrap
import streamlit as st
import os
import pandas as pd
from mcc import call_fracto, write_excel_from_ocr, _extract_rows, MAPPINGS

# ── Session keys ─────────────────────────────────────────────
if "excel_bytes" not in st.session_state:
    st.session_state["excel_bytes"] = None
if "excel_filename" not in st.session_state:
    st.session_state["excel_filename"] = ""

# Ensure FRACTO_API_KEY is available for mcc.call_fracto
if "FRACTO_API_KEY" in st.secrets:
    os.environ["FRACTO_API_KEY"] = st.secrets["FRACTO_API_KEY"]

# ── Page config ───────────────────────────────────────────────
st.set_page_config(page_title="PDF → Smart-OCR → Excel",
                   page_icon="📄", layout="wide")

st.title("Smart-OCR to ERP-ready Excel")

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

    # 3) Save + download edited file
    if st.button("💾 Save edits & download"):
        out_buf = io.BytesIO()
        edited_df.to_excel(out_buf, index=False, engine="openpyxl")
        edited_bytes = out_buf.getvalue()

        st.download_button(
            "⬇️ Download edited Excel",
            data=edited_bytes,
            file_name=st.session_state["excel_filename"].replace(".xlsx", "_edited.xlsx"),
            mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            key="download_edited",
        )