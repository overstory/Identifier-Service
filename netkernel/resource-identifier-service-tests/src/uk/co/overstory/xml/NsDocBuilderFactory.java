package uk.co.overstory.xml;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

public class NsDocBuilderFactory extends DocumentBuilderFactory
{
	private static final String DOCBUILDER_PROP_NAME = "javax.xml.parsers.DocumentBuilderFactory";
	private static final String DEFAULT_DOC_BUILDER_FACTORY = "org.apache.xerces.jaxp.DocumentBuilderFactoryImpl";
	public final DocumentBuilderFactory realFactory;

	public NsDocBuilderFactory()
	{
		String propValue = System.getProperty (DOCBUILDER_PROP_NAME);

		if (propValue == null) {
			// We've been instantiated from a JAR service provider config, delegate to the default parser impl
			System.setProperty (DOCBUILDER_PROP_NAME, DEFAULT_DOC_BUILDER_FACTORY);

			realFactory = DocumentBuilderFactory.newInstance();

			System.clearProperty (DOCBUILDER_PROP_NAME);
		} else {
			// We've been instantiated by being explicitly named in a property, delegate to the platform-defined parser
			System.clearProperty (DOCBUILDER_PROP_NAME);

			realFactory = DocumentBuilderFactory.newInstance();

			System.setProperty (DOCBUILDER_PROP_NAME, propValue);
		}

		realFactory.setNamespaceAware (true);
//		originalFactory.setXIncludeAware (true);
	}

	@Override
	public DocumentBuilder newDocumentBuilder() throws ParserConfigurationException
	{
		return realFactory.newDocumentBuilder();
	}

	@Override
	public void setAttribute (String s, Object o) throws IllegalArgumentException
	{
		realFactory.setAttribute (s, o);
	}

	@Override
	public Object getAttribute (String s) throws IllegalArgumentException
	{
		return realFactory.getAttribute (s);
	}

	@Override
	public void setFeature (String s, boolean b) throws ParserConfigurationException
	{
		realFactory.setFeature (s, b);
	}

	@Override
	public boolean getFeature (String s) throws ParserConfigurationException
	{
		return realFactory.getFeature (s);
	}

	public static void main (String[] args)
	{
		System.setProperty (DOCBUILDER_PROP_NAME, DEFAULT_DOC_BUILDER_FACTORY);

		DocumentBuilderFactory f = DocumentBuilderFactory.newInstance();

		System.out.println ("Factory: " + f.getClass().getName());
	}

}
