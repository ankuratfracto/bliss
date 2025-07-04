# app.py

import io, textwrap
import streamlit as st
import os
from mcc import call_fracto, write_excel_from_ocr, _extract_rows, MAPPINGS

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
        # Read bytes & call OCR
        pdf_bytes = pdf_file.read()
        result    = call_fracto(pdf_bytes, pdf_file.name)
        rows      = _extract_rows(result["data"])

        # Build Excel in-memory
        buffer = io.BytesIO()
        write_excel_from_ocr([result], buffer, overrides=manual_inputs)
        buffer.seek(0)

    st.success("Done! Download your file:")
    st.download_button("⬇️ Download Excel",
                       data=buffer,
                       file_name=pdf_file.name.replace(".pdf", "_ocr.xlsx"),
                       mime=("application/vnd.openxmlformats-officedocument."
                             "spreadsheetml.sheet"))
    # Optional: preview first few rows right in the app
    if st.checkbox("Preview first few rows"):
        import pandas as pd
        df = pd.read_excel(buffer)
        st.dataframe(df.head())
        buffer.seek(0)