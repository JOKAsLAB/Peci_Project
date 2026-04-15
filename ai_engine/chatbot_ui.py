"""
Interface Streamlit para testar o Chatbot localmente.
Uso: streamlit run chatbot_ui.py
"""
import re
import streamlit as st
from chatbot import Chatbot

st.set_page_config(page_title="Chatbot")


@st.cache_resource
def get_chatbot():
    return Chatbot()


def fix_math(text):
    text = re.sub(r"\\\[(.*?)\\\]", r"$$\1$$", text, flags=re.DOTALL)
    return text


chatbot = get_chatbot()

if "messages" not in st.session_state:
    st.session_state.messages = []

for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])

if prompt := st.chat_input("Pergunta ao Mentor..."):
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)

    with st.chat_message("assistant"):
        with st.spinner("A analisar manuais..."):
            resposta, fontes = chatbot.responder_pergunta(prompt)
            resposta_formatada = fix_math(resposta)
            st.markdown(resposta_formatada, unsafe_allow_html=True)
            if fontes:
                with st.expander("🔍 Fontes Consultadas"):
                    for f in fontes:
                        st.write(f)

    st.session_state.messages.append({"role": "assistant", "content": resposta})
