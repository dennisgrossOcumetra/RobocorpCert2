*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Desktop
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault
Library             RPA.Robocloud.Secrets


*** Variables ***
${pdf_folder}       ${CURDIR}${/}pdf_files
${zip_file}         ${CURDIR}${/}output${/}pdf_archive.zip


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${username}=    Starting dialog
    Open the robot order website
    Download csv
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill in the form    ${order}
        Preview the robot
        Wait Until Keyword Succeeds    10x    0.5 sec    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Ending dialog    ${username}
    Close the Browser


*** Keywords ***
Open the robot order website
    ${secret}=    RPA.Robocloud.Secrets.Get Secret    mysecrets
    Open Available Browser    ${secret}[url]

Download csv
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=true

Get orders
    ${table}=    Read table from CSV    orders.csv
    RETURN    ${table}

Close the annoying modal
    Click Button When Visible    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

Fill in the form
    [Arguments]    ${order}
    Select From List By Index    id:head    ${order}[Head]
    Click Element    id:id-body-${order}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    id:address    ${order}[Address]

Preview the robot
    Click Button When Visible    id:preview

Submit the order
    Click Button When Visible    id:order
    Page Should Contain    Receipt

Store the receipt as a PDF file
    [Arguments]    ${Order number}
    Set Local Variable    ${filename}    ${pdf_folder}${/}${ORDER_NUMBER}.pdf
    ${order_receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_receipt}    ${filename}
    RETURN    ${filename}

Take a screenshot of the robot
    [Arguments]    ${Order number}
    Set Local Variable    ${filename}    ${OUTPUT_DIR}${/}${Order number}.png
    Screenshot    id:robot-preview-image    ${filename}
    RETURN    ${filename}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    @{myfiles}=    Create List    ${screenshot}
    Open Pdf    ${pdf}
    Add Files To Pdf    ${myfiles}    ${pdf}    ${True}

Go to order another robot
    Click Button When Visible    id:order-another

Create a ZIP file of the receipts
    Archive Folder With Zip    ${pdf_folder}    ${zip_file}

Starting dialog
    Add heading    Robot Ordering Robot
    Add text input    myname    label=Please enter your name
    ${result}=    Run dialog
    RETURN    ${result.myname}

Ending dialog
    [Arguments]    ${USER_NAME}
    Add icon    Success
    Add heading    Your orders have been processed
    Add text    Dear ${USER_NAME} - all orders have been processed. Have a nice day!
    Run dialog    title=Success

Close the Browser
    Close All Browsers
