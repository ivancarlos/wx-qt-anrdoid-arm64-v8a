#include "wx_app.h"
#include <wx/frame.h>
#include <wx/button.h>

bool MyApp::OnInit()
{
    wxFrame* frame = new wxFrame(
        nullptr,
        wxID_ANY,
        "wxWidgets no Android (backend Qt)",
        wxDefaultPosition,
        wxSize(400, 300)
    );

    new wxButton(
        frame,
        wxID_ANY,
        "Olá de wxWidgets!",
        wxPoint(20, 20),
        wxSize(250, 80)
    );

    frame->Show();
    return true;
}

int MyApp::OnExit()
{
    return wxApp::OnExit();
}

// importante: sem main(), quem manda no processo é o Qt
wxIMPLEMENT_APP_NO_MAIN(MyApp);

