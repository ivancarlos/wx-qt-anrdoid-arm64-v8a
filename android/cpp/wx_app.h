#ifndef WX_APP_H
#define WX_APP_H

#include <wx/app.h>

class MyApp : public wxApp
{
public:
    virtual bool OnInit() override;
    virtual int OnExit() override;
};

#endif // WX_APP_H

