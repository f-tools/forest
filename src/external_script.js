// htmlをdatに変換する処理

function parse(url, startResNumber, html) {
    var lines = "", num, mail, date, name, body;

    var reset = function() {
        num = mail = name = body = date = "";
    };

    var attrRegex = new RegExp(/([^\s]+)=\"([^\"]+)\"/g); 
    var onSeg = function onSeg(attrs, contents) {
        var all = [], arr; 
        if (attrs) {
            while ((arr = attrRegex.exec(attrs)) != null) {
                var attrName = arr[1], value = arr[2];
                if(attrName == "class") {
                    var cls = arr[2];
                    if (cls == "post") {
                        addLine();
                        reset();
                    } else if (cls == "name") {
                        var mailMatch = contents.match(/\"mailto:(.*)\"/);
                        if (mailMatch) {
                            mail = mailMatch[1];
                        }
                        name = contents.replace(/<([^<>]*)>/g,'');
                    } else if (cls=="message") {
                        body = contents;
                    } else if (cls == "date") {
                        date= (contents);
                    }
                } else if (attrName == "data-id") {
                    num = value;
                }
            }
        }
    }


    var addLine = function() {
        if (name && body && Number(num) >= Number(startResNumber)) {
            lines += name + "<>" + mail + "<>" + date + "<>" + body + "<>";
            if (num == 1) {
                var detectedTitle = null;
                var t  = html.indexOf("<title>");
                if (t > -1 ) {
                    var e = html.indexOf("<", t+7);
                    if (e > -1) {
                        detectedTitle = html.substring(t+7, e).trim();
                    }
                }

                if (detectedTitle) {
                    lines += detectedTitle;
                }
            }
            lines += "\n";
        }
    }

    var currentPos = 0, pendingAttr = null;
    while (true) {
        var pos = html.indexOf('<div', currentPos), pos2 = html.indexOf('</div>', currentPos);
        if (pos >= 0  && (pos2==-1 || pos < pos2) ) {
            if (pendingAttr) { onSeg(pendingAttr); pendingAttr = null; }
            var end =  html.indexOf('>', currentPos);
            if (end >= 0) {
                pendingAttr = html.substring(pos+ 4, end);
                currentPos = end+1;
            } else { currentPos = pos + 4; }
        } else if (pos2 >= 0) {
            onSeg(pendingAttr, html.substring(currentPos, pos2)); 
            pendingAttr = null;
            currentPos = pos2+6;
        } else {
            break;
        }
    }

    addLine();

    return lines;
}




var convertHtml2Dat = function(url, startResNumber, html) {
    
    if (html.indexOf("<!DOCTYPE HTML>") >= 0) {
        return parse(url, startResNumber, html);
    }
    
    var dat = ""; var lines = html.split("\n");

    var detectedTitle = null;
    var previousResNumber = -1;
    
    for (var i in lines) {
        var line = lines[i].trim();

        //タイトル
        if (detectedTitle == null) {
            if (line.substring(0,7) == "<title>") {
                detectedTitle = line.substring(7, line.length-8);
            }
        }

        var left = line.indexOf('<dt>');
        if (left >= 0) {
           line = line.substring(left+4);

            //レス番号
            var resMatchArray = line.match(/^[ ]*(\d+)/);
            if (resMatchArray === null) {
                continue;
            }
            var detectedResNumber = Number(resMatchArray[1]);
            var numLen = resMatchArray[0].length;
            line = line.substring(numLen);
            if (detectedResNumber < startResNumber) {
                continue;
            }
            

            //本文を先に取得
            var seps = line.split("<dd>")
            if (seps.length == 1) {
                break;
            }
        
            var body = seps[1];
            if (body.substring(body.length-4) == "<br>") {
                body = body.substring(0, body.length - 4);
            }

            var part = seps[0];// 名前・メール・時刻・ID
            var dateStr = ""
            var dateMatchPos = part.lastIndexOf("：20");
            if (dateMatchPos == -1) {
                var nameStr = part;
            } else {
                var nameStr = part.substring(0, dateMatchPos);
                var dateStr = part.substring(dateMatchPos+1);
                // ID:??? <a href="javascript:be(287993214);">?2BP(1012)</a>
                // BE:287993214-2BP(1012)
                var reg_be = /:be\((\d+)\);\">\?(.*)\((\d+)\)/;
                var beIdMatch = dateStr.match(reg_be);
                dateStr =dateStr.replace(/<(.*)>/g,'');
                
                if (beIdMatch) {
                    var beid =   beIdMatch[1];
                    var bename = beIdMatch[2];
                    var bepoint = beIdMatch[3];
                                              
                    dateStr += "BE:" + beid +"-" + bename+"("+ bepoint+")";
                }
                                              
            }

            var mail = "";

            //trim
            var nameStr = nameStr.replace(/^([\s：:])+|([\s：:])+$/g,'');
            var mailMatch = nameStr.match(/\"mailto:(.*)\"/);
            if (mailMatch) {
                mail = mailMatch[1];
            }

            //タグ消去
            var name = nameStr.replace(/<([^<>]*)>/g,'');

            var datLine = name + "<>" + mail+ "<>" + dateStr +"<>" + body + "<>";
            if (detectedResNumber == 1 && detectedTitle) {
                datLine  += detectedTitle;
            } 

            dat += datLine + "\n";
        }
    }

    return dat;
};


