package ark.models;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.MalformedURLException;
import java.net.URL;


/**
 * 板
 */
public class Board implements java.io.Serializable {
	private static final long serialVersionUID = 1L;

	// http://anago.2ch.net/ghard/
	// http://jbbs.livedoor.jp/computer/10298/
	// http://yy61.60.kg/v2cj/
	// http://jbbs.livedoor.jp/anime/9564/
	public static Board fromUrl(String url) {
		URL urlObj;
		try {
			urlObj = new URL(url);
		} catch (MalformedURLException e) {
			e.printStackTrace();
			return null;
		}

		Board board = new Board();

		String[] pathes = urlObj.getPath().split("/");

		StringBuilder sb = new StringBuilder();
		boolean first = true;
		for (String path : pathes) {
			if (path.trim().equals(""))
				continue;

			if (first)
				first = false;
			else
				sb.append('/');

			sb.append(path);
		}

		board.id = sb.toString();
		board.url = url;
		board.server = urlObj.getHost();

		return board;
	}

	@Override
	public String toString() {
		return name;
	}

	public String id;

	public String name;

	public String server;

	public String url;

	private String _lastModified;

	private Board() {
	}

	public String getBoardKey() {
		if (is2ch()) {
			return id;
		}

		return server + "|" + id;
	}

	@Override
	public boolean equals(Object o) {
		if (o instanceof Board) {
			Board b = (Board) o;
			return b.getBoardKey().equals(this.getBoardKey());
		}

		return false;
	}

	@Override
	public int hashCode() {
		return getBoardKey().hashCode();
	}


	public boolean is2ch() {
		return server != null && id != null && server.contains("2ch.net");
	}

	public boolean isLivedoorBBS() {
		return server != null && (server.contains("jbbs.shitaraba.net")||server.contains("jbbs.livedoor.jp"));
	}

	public boolean isMachiBBS() {
		return server != null && server.contains("machi.to");
	}

	public String getLastModified() {
		return _lastModified;
	}

	public void setLastModified(String headerField) {
		_lastModified = headerField;
	}

	public String getSubjectUrl() {
		if (isMachiBBS()) {
			// Matchi
			// http://[SERVER]/bbs/offlaw.cgi/[BBS]/
			return "http://" + this.server + "/bbs/offlaw.cgi/" + this.id + "/";
		}

		// http://jbbs.livedoor.jp/[カテゴリ]/[掲示板番号]/subject.txt
		if (this.server != null && this.id != null) {
			return "http://" + this.server + "/" + this.id + "/subject.txt";
		}
		return this.url + "/subject.txt";
	}

	public String getBoardEncoding() {
		return this.isLivedoorBBS() ? "EUC-JP" : "MS932";
	}

	public String getOfficialTitle() {
		try {
			String urlStr = isLivedoorBBS() ? ("http://jbbs.shitaraba.net/bbs/api/setting.cgi/" + this.id + "/")
					: this.url + "SETTING.TXT";
			URL url = new URL(urlStr);
			InputStream stream = url.openStream();
			InputStreamReader reader = new InputStreamReader(stream, isLivedoorBBS() ? "EUC-JP" : "MS932");
			BufferedReader br = new BufferedReader(reader);
			String str = null;
			while ((str = br.readLine()) != null) {
				String[] terms = str.split("=", 2);
				if (terms.length == 2 && terms[0].equals("BBS_TITLE")) {
					return terms[1];
				}

			}

		} catch (MalformedURLException e) {
			e.printStackTrace();
			return null;
		} catch (IOException e) {
			e.printStackTrace();
		}

		return null;
	}

	public String getThreadUrl(long id) {
		//http://jbbs.livedoor.jp/bbs/read.cgi/anime/9564/1339063411/
		if (isLivedoorBBS()) {
			return "http://" + server + "/bbs/read.cgi/" + this.id + "/" + id + "/";
		} else if (isMachiBBS()) {
			return "http://" + server + "/bbs/read.cgi/" + this.id + "/" + id + "/";
		} else {
			return "http://" + server + "/test/read.cgi/" + this.id + "/" + id + "/";
		}
		//http://kanto.machi.to/bbs/read.cgi/kanto/1350492433/
		//http://toro.2ch.net/test/read.cgi/tech/1349932734/
		//return null;
	}
}

